#!/bin/sh
# vim: set syn=sh ai et sw=2 st=2 ts=2 tw=0:
#
# This file is part of SaLT.
cd $(dirname $0)
. ./config
BL=grub2
IMAGE=bg.png
KERNEL=
DEBUG=
VOLNAME='SaLT'
ISONAME='salt.iso'
# MemTest86+ version
MEMTEST_VER=4.20
# Syslinux+ version
SYSLINUX_VER=4.04
# Compression used for the initrd, default to gz
[ -z "$COMP" ] && COMP=gz
while [ -n "$1" ]; do
  case "$1" in
    '-h'|'--help')
      echo 'create-iso.sh -l|-g [-i image] [-k kernelpackage] [-d 0|1] [-v volume_name] [-o iso_name]'
      echo '  -l: specify to use isolinux'
      echo '  -g: specify to use grub2 (default)'
      echo '  -i image: specify an image to use as background. The image will be converted to PNG 8bit 640x480.'
      echo '    The conversion is done through Image Magic and xcftools if needed. Default: bg.png'
      echo '  -k kernelpackage: specify a kernel package to use for kernel modules and vmlinuz.'
      echo '    If not specified, the data will be get from the "kernel" directory'
      echo '  -d 0: non debug (default), 1: debug. If debug is specified, it is injected as a default kernel parameter'
      echo '  -v volume_name: name of the CD, 32 chars maximum (default SaLT).'
      echo '  -o iso_name: name of the ISO file (default salt.iso).'
      exit
      ;;
    '-l')
      BL=isolinux
      shift
      ;;
    '-g')
      BL=grub2
      shift
      ;;
    '-i')
      shift
      IMAGE="$1"
      shift
      ;;
    '-k')
      shift
      KERNEL="$1"
      shift
      ;;
    '-d')
      shift
      [ "$1" = "0" ] && DEBUG=
      [ "$1" = "1" ] && DEBUG=debug
      shift
      ;;
    '-v')
      shift
      VOLNAME="$1"
      shift
      ;;
    '-o')
      shift
      export ISONAME="$1"
      shift
      ;;
    *)
      echo "Syntax error, use $0 -h or $0 --help"
      exit 1
      ;;
  esac
done
if [ -n "$KERNEL" ]; then
  mkdir -p kernel
  ( cd kernel; tar xf "$KERNEL" )
fi
./create-initrd.sh $COMP $DEBUG
if [ $? -eq 0 ]; then
  BOOTFILE=
  CATALOGFILE=
  [ ! -e mt86p ] && wget "http://www.memtest.org/download/$MEMTEST_VER/memtest86+-$MEMTEST_VER.bin.gz" -O - | zcat > mt86p
  [ ! -e syslinux-$SYSLINUX_VER.tar.bz2 ] && wget http://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-$SYSLINUX_VER.tar.bz2
  ISODIR=$(mktemp -d)
  mkdir -p $ISODIR/$ROOT_DIR/persistence
  echo "ident_content=$IDENT_CONTENT" > $ISODIR/$IDENT_FILE
  echo "basedir=/" >> $ISODIR/$IDENT_FILE
  echo "iso_name=$(basename $ISONAME)" >> $ISODIR/$IDENT_FILE
  # generate background image
  if [ ! -e $IMAGE ]; then
    echo "$IMAGE not found" >&2
    exit 1
  fi
  infos=$(identify "$IMAGE")
  (echo "$infos" | grep -q 'PNG 640x480') && (echo "$infos" | grep -q ' 8-bit ')
  if [ $? -eq 0 ]; then
    cp "$IMAGE" .bg.png
  else
    echo "Image needs conversion"
    echo "Format: "$(file -L $IMAGE)
    if file -L "$IMAGE"|grep -q 'GIMP XCF image data'; then
      echo "Converting from GIMP XCF format to 8 bits 640x480 png..."
      xcf2png "$IMAGE" | convert -depth 8 -alpha deactivate -type truecolor -define png:color-type=2 -resize 640x480 - .bg.png
    else
      echo "Converting from bitmap to 8 bits 640x480 png..."
      convert -flatten -depth 8 -alpha deactivate -type truecolor -define png:color-type=2 -resize 640x480 "$IMAGE" .bg.png
    fi
  fi
  if [ $? -ne 0 ]; then
    echo "error in converting $IMAGE to the correct format" >&2
    exit 1
  fi
  if [ "$BL" = "isolinux" ]; then
    BOOTFILE=isolinux/isolinux.bin
    CATALOGFILE=isolinux/isolinux.cat
    ISOLINUX_DIR=/usr/share/syslinux
    cp -r isolinux $ISOLINUX_DIR/isolinux.bin $ISOLINUX_DIR/vesamenu.c32 $ISODIR/
    cp kernel/boot/vmlinuz-* $ISODIR/isolinux/vmlinuz
    cp initrd.$COMP $ISODIR/isolinux/initrd.$COMP
    cp mt86p $ISODIR/isolinux/mt86p
    mv .bg.png $ISODIR/isolinux/bg.png
    sed -i "s:\(.*/dev/ram0\).*:\1 $DEBUG:; s/_DISTRONAME_/$VOLNAME/g" $ISODIR/isolinux/isolinux.cfg
    sed -i "s:initrd\.gz:initrd.$COMP:" $ISODIR/isolinux/isolinux.cfg
  else
    BOOTFILE=boot/eltorito.img
    CATALOGFILE=boot/grub.cat
    mkdir -p $ISODIR/boot
    cp kernel/boot/vmlinuz-* $ISODIR/boot/vmlinuz
    cp initrd.$COMP $ISODIR/boot/initrd.$COMP
    cp mt86p $ISODIR/boot/mt86p
    grubdir="$PWD/.grub2"
    [ -e $grubdir ] && rm -rf $grubdir
    cp -r grub2 $grubdir
    mv .bg.png "$grubdir/build/boot/grub/bg.png"
    # generate grub config
    (
      cd "$grubdir/genlocale"
      # compile mo files, create locale dir containg translations
      make install
      ./genlocale "$grubdir/build/boot/grub/locale" "$grubdir/build/boot/grub" "$grubdir/build/boot/grub/keymaps" "$VOLNAME"
    )
    # add grub2 menu
    (
      cd $ISODIR
      # determine grub files location
      eval $(grep '^prefix=' $(which grub-mkrescue))
      eval $(grep '^exec_prefix=' $(which grub-mkrescue))
      # libdir might rely on the previous two
      eval $(grep '^libdir=' $(which grub-mkrescue))
      eval $(grep '^PACKAGE_TARNAME=' $(which grub-mkrescue))
      GRUB_DIR=$libdir/$PACKAGE_TARNAME/i386-pc
      # copy the config files
      mkdir -p boot/grub
      cp -ar "$grubdir"/build/* .
      # modify the config files
      sed -i "s:\(set debug=\).*:\1$DEBUG:" boot/grub/grub.cfg
      sed -i "s:initrd\.gz:initrd.$COMP:" boot/grub/boot.cfg
      sed -i -e "s:\(ident_file=\).*:\1$IDENT_FILE:" \
        -e "s:\(searched_ident_content=\).*:\1$IDENT_CONTENT:" \
        -e "s:\(default_iso_name=\).*:\1$(basename $ISONAME):" boot/grub/memdisk_grub.cfg
      # install locales
      mkdir -p boot/grub/locale/
      for i in /usr/share/locale/*; do
        if [ -f "$i/LC_MESSAGES/grub.mo" ]; then
          cp -f "$i/LC_MESSAGES/grub.mo" "boot/grub/locale/${i##*/}.mo"
        fi
      done
      # copy modules and other grub files
      mkdir -p boot/grub/i386-pc/
      for i in $GRUB_DIR/*.mod $GRUB_DIR/*.lst $GRUB_DIR/*.img $GRUB_DIR/efiemu??.o; do
        if [ -f $i ]; then
          cp -f $i boot/grub/i386-pc/
        fi
      done
      # create the boot images
      rm -rf /tmp/memdisk /tmp/memdisk.tar
      mkdir -p /tmp/memdisk/boot/grub
      cp boot/grub/memdisk_grub.cfg /tmp/memdisk/boot/grub/grub.cfg
      (
        cd /tmp/memdisk
        tar -cf /tmp/memdisk.tar boot
      )
      # memdisk allows us to switch to normal mode, embedded config not
      # normal mode in turn allows for extended syntax like loops
      # zfs causes slow disk access with 1.99
      grub-mkimage -p /boot/grub -o /tmp/core.img -O i386-pc -m /tmp/memdisk.tar \
        biosdisk ext2 fat iso9660 ntfs reiserfs xfs part_msdos part_gpt \
        memdisk tar configfile loopback \
        normal extcmd regexp test read echo
      cat $GRUB_DIR/lnxboot.img /tmp/core.img > boot/grub2-linux.img
      if [ -e $GRUB_DIR/g2hdr.img ] && [ -e $GRUB_DIR/g2ldr.mbr ]; then
		    # this image can only be directly loaded by Vista and later
        cat $GRUB_DIR/g2hdr.img /tmp/core.img > boot/g2ldr
        # this image just loads the g2ldr image (so don't rename it!)
        # it must be used by xp and earlier
        cp $GRUB_DIR/g2ldr.mbr boot/g2ldr.mbr
      else
        echo "You're version of grub lacks ntldr-img from grub-extras. Disabling generation of ntldr images."
      fi
      rm -r /tmp/memdisk /tmp/memdisk.tar
      rm /tmp/core.img
      grub-mkimage -p /boot/grub/i386-pc -o /tmp/core.img -O i386-pc \
        biosdisk iso9660
      cat $GRUB_DIR/cdboot.img /tmp/core.img > $BOOTFILE
      rm /tmp/core.img
      # create the env file used for saving settings
      grub-editenv boot/grub/salt.env create
    )
    # add script files and boot loader install for USB
    cp -v "$grubdir"/install-on-USB* $ISODIR/boot/
    tar xf syslinux-$SYSLINUX_VER.tar.bz2
    cp -v syslinux-$SYSLINUX_VER/win32/syslinux.exe $ISODIR/boot/
    rm -rf syslinux-$SYSLINUX_VER
    rm -r "$grubdir"
  fi
  cp -rv overlay/* $ISODIR/
  find $ISODIR -name '.svn' -type d -prune -exec rm -rf '{}' +
  mkisofs -r -J -V "$VOLNAME" -b $BOOTFILE -c $CATALOGFILE -no-emul-boot -boot-load-size 4 -boot-info-table -o "$ISONAME" $ISODIR
  rm -rf $ISODIR
fi

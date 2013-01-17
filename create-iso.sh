#!/bin/sh
# vim: set syn=sh ai et sw=2 st=2 ts=2 tw=0:
#
# This file is part of SaLT.
cd $(dirname $0)
. ./config
IMAGE='bg.png'
KERNEL=
DEBUG=
VOLNAME='SaLT'
ISONAME='salt.iso'
# MemTest86+ version
MEMTEST_VER=4.20
MEMTEST_URL="http://www.memtest.org/download/$MEMTEST_VER/memtest86+-$MEMTEST_VER.bin.gz"
# Syslinux version
SYSLINUX_VER=4.06
SYSLINUX_URL="http://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-$SYSLINUX_VER.tar.xz"
# Elevate.exe is a tool similar to sudo/gksudo for windows vista+ (but without password).
# Home page: http://jpassing.com/2007/12/08/launch-elevated-processes-from-the-command-line/
# Licence: MIT
ELEVATE_URL="int3.de/download/Elevate.zip"
# Compression used for the initrd, default to gz
[ -z "$COMP" ] && COMP='gz'
while [ -n "$1" ]; do
  case "$1" in
    '-h'|'--help')
      echo 'create-iso.sh [-i image] [-k kernelpackage] [-d 0|1] [-v volume_name] [-o iso_name]'
      echo '  -i image: specify an image to use as background. The image will be converted to PNG 8bit 640x480.'
      echo '    The conversion is done through Image Magic and xcftools if needed. Default: bg.png'
      echo '  -k kernelpackage: specify a kernel package to use for kernel modules and vmlinuz.'
      echo '    If not specified, the data will be get from the "kernel" directory'
      echo '  -d 0: non debug (default), 1: debug. If debug is specified, it is injected as a default kernel parameter'
      echo '  -v volume_name: name of the CD, 32 chars maximum (default SaLT).'
      echo '  -o iso_name: name of the ISO file (default salt.iso).'
      exit
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
      [ "$1" = "1" ] && DEBUG=salt_debug
      shift
      ;;
    '-v')
      shift
      VOLNAME="$1"
      shift
      ;;
    '-o')
      shift
      ISONAME="$1"
      export ISONAME
      shift
      ;;
    *)
      echo "Syntax error, use $0 -h or $0 --help"
      exit 1
      ;;
  esac
done
[ -e mt86p ] || wget "$MEMTEST_URL" -O - | zcat > mt86p
[ -e syslinux-$SYSLINUX_VER.tar.xz ] || wget "$SYSLINUX_URL"
[ -e Elevate.zip ] || wget "$ELEVATE_URL"
if [ -n "$KERNEL" ]; then
  [ -e kernel ] && rm -rf kernel
  mkdir -p kernel
  ( cd kernel; tar xf "$KERNEL" )
fi
./create-initrd.sh $COMP $DEBUG
if [ $? -eq 0 ]; then
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
  BOOTFILE=boot/isolinux/isolinux.bin
  CATALOGFILE=boot/eltorito.cat
  tar xf syslinux-$SYSLINUX_VER.tar.xz
  mkdir -p $ISODIR/boot/isolinux
  cat <<EOF > $ISODIR/boot/isolinux/isolinux.cfg
DEFAULT grub2
PROMPT 0
NOESCAPE 1
TOTALTIMEOUT 1
ONTIMEOUT grub2
SAY Chainloading to grub2...
LABEL grub2
  COM32 /boot/isolinux/chain.c32
  APPEND file=/boot/g2l.img

EOF
  cp -v syslinux-$SYSLINUX_VER/core/isolinux.bin $ISODIR/$BOOTFILE
  cp -v syslinux-$SYSLINUX_VER/mbr/mbr.bin $ISODIR/boot/
  cp -v syslinux-$SYSLINUX_VER/mbr/isohdpfx.bin .
  cp -v syslinux-$SYSLINUX_VER/win32/syslinux.exe $ISODIR/boot/
  cp -v syslinux-$SYSLINUX_VER/com32/chain/chain.c32 $ISODIR/boot/isolinux/
  rm -rf syslinux-$SYSLINUX_VER
  mkdir elevate
  ( cd elevate && unzip ../Elevate.zip )
  cp -v elevate/bin/x86/Release/Elevate.exe $ISODIR/boot/elevate.exe
  rm -rf elevate
  cp -v kernel/boot/vmlinuz-* $ISODIR/boot/vmlinuz
  cp -v initrd.$COMP $ISODIR/boot/initrd.$COMP
  cp -v mt86p $ISODIR/boot/mt86p
  grubdir="$PWD/.grub2"
  [ -e $grubdir ] && rm -rf $grubdir
  cp -r grub2 $grubdir
  mv .bg.png "$grubdir/build/boot/grub/bg.png"
  cp initrd-template/lib/keymaps "$grubdir/"
  # generate grub config
  (
    cd "$grubdir/generate"
    echo "Create locale + timezone dirs containg translations"
    rm -rf "$grubdir/build/boot/grub/locale" "$grubdir/build/boot/grub/keymaps" "$grubdir/build/boot/grub/timezone"
    ./generate "$grubdir/build/boot/grub" "$grubdir/build/boot/grub/keymaps" "$grubdir/keymaps" "$grubdir/build/boot/grub/timezone"
    echo "Compile mo files"
    make clean all DISTRONAME="$VOLNAME"
    mkdir -p "$grubdir/build/boot/grub/locale"
    for i in po/*.mo; do
      gzip -9 -vc "$i" > "$grubdir/build/boot/grub/locale/$(basename "$i").gz"
    done
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
    sed -i "s:\(set salt_debug\)=.*:\1=$DEBUG:" boot/grub/grub.cfg
    for cfg in boot.cfg simpleboot.cfg; do
      sed -i "s:_DISTRONAME_:$VOLNAME:" boot/grub/$cfg
    done
    sed -i "s,initrd\.gz,initrd.$COMP," boot/grub/boot.cfg
    sed -i -e "s,\(ident_file=\).*,\1$IDENT_FILE," \
      -e "s,\(searched_ident_content=\).*,\1$IDENT_CONTENT," \
      -e "s,\(default_iso_name=\).*,\1$(basename $ISONAME)," boot/grub/memdisk_grub.cfg
    # copy modules and other grub files
    mkdir -p boot/grub/i386-pc/
    for i in $GRUB_DIR/*.mod $GRUB_DIR/*.lst $GRUB_DIR/*.img $GRUB_DIR/efiemu??.o; do
      if [ -f $i ]; then
        cp -f $i boot/grub/i386-pc/
      fi
    done
    # memdisk allows us to switch to normal mode, embedded config not.
    # normal mode in turn allows for extended syntax like loops.
    memdisktmp=$(mktemp -d)
    mkdir -p $memdisktmp/boot/grub
    cp boot/grub/memdisk_grub.cfg $memdisktmp/boot/grub/grub.cfg
    tar -C $memdisktmp -cf $memdisktmp/memdisk.tar boot
    # create the core grub2 image file.
    coreimg=$(mktemp)
    grub-mkimage -p /boot/grub -o $coreimg -O i386-pc -m $memdisktmp/memdisk.tar \
      biosdisk btrfs ext2 fat iso9660 ntfs reiserfs udf xfs zfs part_msdos part_gpt \
      memdisk tar configfile loopback \
      normal extcmd regexp test read echo
    # create a linux-kernel-like grub2 image, thus that can be booted by isolinux/syslinux/...
    cat $GRUB_DIR/lnxboot.img $coreimg > boot/g2l.img
    if [ -e $GRUB_DIR/g2hdr.img ] && [ -e $GRUB_DIR/g2ldr.mbr ]; then
      # this image can only be directly loaded by Vista and later
      cat $GRUB_DIR/g2hdr.img $coreimg > boot/g2ldr
      # this image just loads the g2ldr image (so don't rename it!)
      # it must be used by xp and earlier
      cp $GRUB_DIR/g2ldr.mbr boot/g2ldr.mbr
    else
      echo "You're version of grub lacks ntldr-img from grub-extras. Disabling generation of ntldr images." >&2
    fi
    rm -r $memdisktmp $coreimg
    # create the env file used for saving settings
    grub-editenv boot/grub/salt.env create
  )
  # add script files and boot loader install for USB
  cp -v "$grubdir"/install-on-USB* $ISODIR/boot/
  cp -v "$grubdir"/README-UsbInstall $ISODIR/
  # remove temp grub directory
  rm -r "$grubdir"
  # copy the rest to the isodir
  cp -rv overlay/* $ISODIR/
  # ensure there is no versioning files in the ISO
  find $ISODIR -type d \( -name '.cvs' -o -name '.svn' -o -name '.git' -o -name '.gitkeep' -o -name '.gitignore' \) -prune -exec rm -rf '{}' +
  # create iso using the bootfile for el torito and creating the catalog file.
  xorriso -as mkisofs \
    -r \
    -J \
    -V "$VOLNAME" \
    -A "$VOLNAME" \
    -p "SaLT v$(cat version)" \
    -publisher "SaLT v$(cat version)" \
    -b $BOOTFILE \
    -c $CATALOGFILE \
    -isohybrid-mbr isohdpfx.bin \
    -partition_offset 16 \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o "$ISONAME" \
    $ISODIR
  # remove temp iso dir.
  rm -rf $ISODIR
fi

#!/bin/sh
cd $(dirname $0)
. ./config
BL=isolinux
IMAGE=bg.png
DEBUG=
VOLNAME='SaLT'
ISONAME='salt.iso'
# MemTest86+ version
MEMTEST_VER=4.10
while [ -n "$1" ]; do
  case "$1" in
    '-h'|'--help')
      echo 'create-iso.sh -l|-g [-i image] [-d 0|1] [-v volume_name] [-o iso_name]'
      echo '  -l: specify to use isolinux (default)'
      echo '  -g: specify to use grub2'
      echo '  -i image: specify an image to use as background. The image will be converted to PNG 8bit 640x480.'
      echo '    The conversion is done through Image Magic and xcftools if needed. Default: bg.png'
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
      IMAGE=$1
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
      VOLNAME=$1
      shift
      ;;
    '-o')
      shift
      export ISONAME=$1
      shift
      ;;
    *)
      echo "Syntax error, use $0 -h or $0 --help"
      exit 1
      ;;
  esac
done
./create-initrd.sh
if [ $? -eq 0 ]; then
  BOOTFILE=
  CATALOGFILE=
  [ ! -e mt86p ] && wget "http://www.memtest.org/download/$MEMTEST_VER/memtest86+-$MEMTEST_VER.bin.gz" -O - | zcat > mt86p
  [ -e .iso ] && rm -rf .iso
  mkdir -p .iso/$ROOT_DIR
  echo "$IDENT_CONTENT" > .iso/$IDENT_FILE
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
    if file "$IMAGE"|grep -q 'GIMP XCF image data'; then
      xcf2png "$IMAGE" | convert -depth 8 -alpha deactivate -type truecolor -resize 640x480 - .bg.png
    else
      convert -flatten -depth 8 -alpha deactivate -type truecolor -resize 640x480 "$IMAGE" .bg.png
    fi
  fi
  if [ $? -ne 0 ]; then
    echo "error in converting $IMAGE to the correct format" >&2
    exit 1
  fi
  if [ "$BL" = "isolinux" ]; then
    cp -r isolinux .iso/
    cp kernel/boot/vmlinuz-* .iso/isolinux/vmlinuz
    cp initrd.gz .iso/isolinux/initrd.gz
    cp mt86p .iso/isolinux/mt86p
    mv .bg.png .iso/isolinux/bg.png
    sed -i "s:\(.*/dev/ram0\).*:\1 $DEBUG:; s/_DISTRONAME_/$VOLNAME/g" .iso/isolinux/isolinux.cfg
    BOOTFILE=isolinux/isolinux.bin
    CATALOGFILE=isolinux/isolinux.cat
  else
    mkdir -p .iso/boot
    cp kernel/boot/vmlinuz-* .iso/boot/vmlinuz
    cp initrd.gz .iso/boot/initrd.gz
    cp mt86p .iso/boot/mt86p
    grubdir="$PWD/.grub2"
    [ -e $grubdir ] && rm -rf $grubdir
    cp -r grub2 $grubdir
    mv .bg.png "$grubdir/build/boot/grub/bg.png"
    # generate grub config
    (
      cd "$grubdir/genlocale"
      find po -name '.svn' -type d -prune -exec rm -rf '{}' +
      find po -type f -exec sed -i "s/_DISTRONAME_/$VOLNAME/" '{}' \;
      sed -i "s/_DISTRONAME_/$VOLNAME/" genlocale
      # compile mo files, create locale dir containg translations
      make install
      ./genlocale "$grubdir/build/boot/grub/locale" "$grubdir/build/boot/grub"
    )
    # add grub2 menu
    (
      cd .iso
      # prepare the grub2 initial tree
      mkdir -p boot
      # ask grub2 to build the rescue ISO to get the initial tree
      grub-mkrescue --output=rescue.iso
      mkdir rescue && mount -o loop rescue.iso rescue
      cp -r rescue/boot/* boot/ && chmod u+w -R boot
      umount rescue && rm -r rescue*
      grub-mkimage -o boot/grub/core.img
      cp -ar "$grubdir"/build/* .
      cat "$grubdir"/grub.cfg >> boot/grub/grub.cfg
      sed -i "s:\(set debug=\).*:\1$DEBUG:" boot/grub/grub.cfg
      # remove uneeded files
      rm -r "$grubdir"
      # copy the mod files and lst files to the grub directory too for USB support.
      find boot/grub -name '*.mod' -exec cp -v '{}' boot/grub/ \;
      find boot/grub -name '*.lst' -exec cp -v '{}' boot/grub/ \;
    )
    BOOTFILE=boot/grub/i386-pc/eltorito.img
    CATALOGFILE=boot/grub.cat
  fi
  cp -rv overlay/* .iso/
  find .iso -name '.svn' -type d -prune -exec rm -rf '{}' +
  mkisofs -r -J -V "$VOLNAME" -b $BOOTFILE -c $CATALOGFILE -no-emul-boot -boot-load-size 4 -boot-info-table -o "$ISONAME" .iso
fi

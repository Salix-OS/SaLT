#!/bin/bash
qemu --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo ""
  echo "WARNING: qemu not installed!"
  echo ""
  QEMU=0
else
  QEMU=1
fi
cd "$(dirname "$0")"
startdir="$PWD"
ISODIR="$startdir"/iso
grubdir="$startdir"
rm -rf "$ISODIR"
mkdir -p "$ISODIR"
BOOTFILE=boot/eltorito.img
CATALOGFILE=boot/grub.cat
cp bg.png "$grubdir/build/boot/grub/bg.png"
cp ../initrd-template/lib/keymaps "$grubdir/"
# generate grub config
(
  cd "$grubdir/generate"
  echo "Compile mo files"
  make install
  echo "Create locale + timezone dirs containg translations"
  mkdir -p "$grubdir/build/boot/grub/locale" "$grubdir/build/boot/grub/keymaps" "$grubdir/build/boot/grub/timezone"
  ./generate "$grubdir/build/boot/grub/locale" "$grubdir/build/boot/grub" "$grubdir/build/boot/grub/keymaps" "$grubdir/keymaps" "$grubdir/build/boot/grub/timezone" "GRUB2 Test"
)
rm "$grubdir/keymaps"
# add grub2 menu
(
  echo "Copy grub files to $ISODIR"
  cd "$ISODIR"
  # prepare the grub2 initial tree
  eval $(grep '^prefix=' $(which grub-mkrescue))
  eval $(grep '^exec_prefix=' $(which grub-mkrescue))
  # libdir might rely on the previous two
  eval $(grep '^libdir=' $(which grub-mkrescue))
  eval $(grep '^PACKAGE_TARNAME=' $(which grub-mkrescue))
  GRUB_DIR=$libdir/$PACKAGE_TARNAME/i386-pc
  mkdir -p boot/grub
  cp -arv "$grubdir"/build/* .
  sed -i "s:\(set debug=\).*:\1=debug:" boot/grub/grub.cfg
  mkdir -p boot/grub/locale/
  for i in /usr/share/locale/*; do
    if [ -f "$i/LC_MESSAGES/grub.mo" ]; then
      cp -fv "$i/LC_MESSAGES/grub.mo" "boot/grub/locale/${i##*/}.mo"
    fi
  done
  mkdir -p boot/grub/i386-pc/
  for i in $GRUB_DIR/*.mod $GRUB_DIR/*.lst $GRUB_DIR/*.img $GRUB_DIR/efiemu??.o; do
    if [ -f $i ]; then
      cp -fv $i boot/grub/i386-pc/
    fi
  done
  echo "Creating grub image core.img"
  grub-mkimage -p /boot/grub -o /tmp/core.img -O i386-pc biosdisk iso9660
  echo "Prepending cdboot.img to it"
  cat $GRUB_DIR/cdboot.img /tmp/core.img > $BOOTFILE
  rm /tmp/core.img
  echo "Creating salt.env"
  grub-editenv boot/grub/salt.env create
)
# remove uneeded/unwanted files
rm -rf boot/dos boot/isolinux boot/pxelinux.cfg boot/syslinux boot/bootinst.* boot/*.c32 boot/liloinst.sh
echo "Creating ISO..."
cd "$startdir"
mkisofs -r -J -V "grub2_menu" -b $BOOTFILE -c $CATALOGFILE -no-emul-boot -boot-load-size 4 -boot-info-table -o "grub2menu.iso" "$ISODIR"
if [ $QEMU -eq 1 ]; then
  echo "Launching qemu..."
  qemu -cdrom grub2menu.iso -boot order=d
  echo "Press a key to terminate..."
  read R
  rm -rf "$ISODIR"
  rm grub2menu.iso
else
  rm -rf "$ISODIR"
fi

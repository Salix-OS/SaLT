#!/bin/bash
qemu --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo ""
  echo "WARNING: qemu not installed!"
  echo ""
fi
cd $(dirname $0)
startdir=$PWD
ISODIR=$startdir/iso
grubdir=$startdir
rm -rf $ISODIR
mkdir -p $ISODIR
mv bg.png "$grubdir/build/boot/grub/bg.png"
# generate grub config
(
  cd "$grubdir/genlocale"
  find po -name '.svn' -type d -prune -exec rm -rf '{}' +
  find po -type f -exec sed -i "s/_DISTRONAME_/$VOLNAME/" '{}' \;
  sed -i "s/_DISTRONAME_/GRUB2 Test/" genlocale
  # compile mo files, create locale dir containg translations
  make install
  ./genlocale "$grubdir/build/boot/grub/locale" "$grubdir/build/boot/grub" "$grubdir/build/boot/grub/keymaps"
)
# add grub2 menu
(
  cd $ISODIR
  # prepare the grub2 initial tree
  eval $(grep '^libdir=' $(which grub-mkrescue))
  eval $(grep '^PACKAGE_TARNAME=' $(which grub-mkrescue))
  GRUB_DIR=$libdir/$PACKAGE_TARNAME/i386-pc
  mkdir -p boot
  grub-mkimage -p /boot/grub -o /tmp/core.img -O i386-pc iso9660 biosdisk
  cat $GRUB_DIR/cdboot.img /tmp/core.img > boot/eltorito.img
  rm /tmp/core.img
  cp -ar "$grubdir"/build/* .
  cat "$grubdir"/grub.cfg >> boot/grub/grub.cfg
  mkdir -p boot/grub/locale/
  for i in /usr/share/locale/*; do
    if [ -f "$i/LC_MESSAGES/grub.mo" ]; then
      cp -f "$i/LC_MESSAGES/grub.mo" "boot/grub/locale/${i##*/}.mo"
    fi
  done
  for i in $GRUB_DIR/*.mod $GRUB_DIR/*.lst $GRUB_DIR/*.img $GRUB_DIR/efiemu??.o; do
    if [ -f $i ]; then
      cp -f $i boot/grub/
    fi
  done
)
BOOTFILE=boot/eltorito.img
CATALOGFILE=boot/grub.cat
# remove uneeded/unwanted files
rm -rf boot/dos boot/isolinux boot/pxelinux.cfg boot/syslinux boot/bootinst.* boot/*.c32 boot/liloinst.sh
# create the iso
echo "Creating ISO..."
find . -name '.svn' -exec rm -rf '{}' \; 2>/dev/null
cd $startdir
mkisofs -r -J -V "grub2_menu" -b $BOOTFILE -c $CATALOGFILE -no-emul-boot -boot-load-size 4 -boot-info-table -o "grub2menu.iso" $ISODIR
rm -rf $ISODIR
qemu -cdrom grub2menu.iso
read R
rm grub2menu.iso

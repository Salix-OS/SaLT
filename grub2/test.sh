#!/bin/bash
# vim: set et sw=2 st=2 tw=0:
if qemu -version >/dev/null 2>&1; then
  QEMU=qemu
elif qemu-system-i386 -version >/dev/null 2>&1; then
  QEMU=qemu-system-i386
elif qemu-system-x86_64 -version >/dev/null 2>&1; then
  QEMU=qemu-system-x86_64
else
  echo ""
  echo "WARNING: qemu not installed!"
  echo ""
  QEMU=''
fi
cd "$(dirname "$0")"
startdir="$PWD"
# MemTest86+ version
MEMTEST_VER=4.20
MEMTEST_URL="http://www.memtest.org/download/$MEMTEST_VER/memtest86+-$MEMTEST_VER.bin.gz"
# Syslinux version
SYSLINUX_VER=4.06
SYSLINUX_URL="http://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-$SYSLINUX_VER.tar.xz"
ISODIR="$startdir"/iso
grubdir="$startdir"
rm -rf "$ISODIR"
mkdir -p "$ISODIR"
BOOTFILE=boot/eltorito.img
CATALOGFILE=boot/eltorito.cat
export DISTRONAME="GRUB2 Test"
[ -e ../mt86p ] || wget "$MEMTEST_URL" -O - | zcat > ../mt86p
[ -e ../syslinux-$SYSLINUX_VER.tar.xz ] || wget "$SYSLINUX_URL" -O ../syslinux-$SYSLINUX_VER.tar.xz
tar xf ../syslinux-$SYSLINUX_VER.tar.xz
mkdir -p $ISODIR/boot/isolinux
cat <<EOF > $ISODIR/boot/isolinux/isolinux.cfg
DEFAULT grub2
PROMPT 0
NOESCAPE 1
TOTALTIMEOUT 1
ONTIMEOUT grub2
SAY Chainloading to grub2...
LABEL grub2
  COM32 /boot/chain.c32
  APPEND file=/boot/g2l.img

EOF
cp -v syslinux-$SYSLINUX_VER/core/isolinux.bin $ISODIR/$BOOTFILE
cp -v syslinux-$SYSLINUX_VER/mbr/mbr.bin $ISODIR/boot/
cp -v syslinux-$SYSLINUX_VER/mbr/isohdpfx.bin .
cp -v syslinux-$SYSLINUX_VER/com32/chain/chain.c32 $ISODIR/boot/
# creating hdt.img
(
  cd syslinux-$SYSLINUX_VER/com32/hdt
  sed -i '/^hdt.elf/ { s/^/#/; n; s/^/#/ }' Makefile
  cp "$startdir"/../mt86p floppy/memtest.bin
  make hdt.img
  cp -L -v hdt.img $ISODIR/boot/hdt.img
)
cp -v syslinux-$SYSLINUX_VER/memdisk/memdisk $ISODIR/boot/
cp -v ../mt86p $ISODIR/boot/mt86p
rm -rf syslinux-$SYSLINUX_VER
if [ -e bg.png ]; then
  cp bg.png "$grubdir/build/boot/grub/bg.png"
fi
if [ -d themes ]; then
  theme_name=$(basename $(find themes/ -type d -mindepth 1 | head -n 1))
  export theme_name
  echo "** theme = $theme_name **"
fi
cp ../initrd-template/lib/keymaps "$grubdir/"
# generate grub config
(
  cd "$grubdir/generate"
  echo "Create locale + timezone dirs containg translations"
  rm -rf "$grubdir/build/boot/grub/locale" "$grubdir/build/boot/grub/keymaps" "$grubdir/build/boot/grub/timezone"
  rm -f "$grubdir/build/boot/grub/"{lang.cfg,keyboard.cfg,timezone.cfg}
  ./generate "$grubdir/build/boot/grub" "$grubdir/build/boot/grub/keymaps" "$grubdir/keymaps" "$grubdir/build/boot/grub/timezone"
  echo "Compile mo files"
  make clean all DISTRONAME="$DISTRONAME"
  mkdir -p "$grubdir/build/boot/grub/locale"
  cp -v po/*.mo.gz "$grubdir/build/boot/grub/locale/"
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
  sed -i "s:\(set salt_debug=\).*:\1=salt_debug:" boot/grub/grub.cfg
  for cfg in boot.cfg simpleboot.cfg; do
    sed -i "s:_DISTRONAME_:$DISTRONAME:" boot/grub/$cfg
  done
  echo "ident_content=test" > salix.live
  echo "basedir=/" >> salix.live
  echo "iso_name=grub2menu.iso" >> salix.live
  sed -i -e "s,\(ident_file=\).*,\1salix.live," \
    -e "s,\(searched_ident_content=\).*,\1test," \
    -e "s,\(default_iso_name=\).*,\1grub2menu.iso," boot/grub/memdisk_grub.cfg
  if [ -n "$theme_name" ]; then
    mkdir -p boot/grub/themes
    cp -r $startdir/themes/$theme_name boot/grub/themes/
    sed -i "s:^#\(set theme_name\)=.*:\1=\"$theme_name\":" boot/grub/include.cfg
  fi
  mkdir -p boot/grub/i386-pc/
  for i in $GRUB_DIR/*.mod $GRUB_DIR/*.lst $GRUB_DIR/*.img $GRUB_DIR/efiemu??.o; do
    if [ -f $i ]; then
      cp -fv $i boot/grub/i386-pc/
    fi
  done
  echo "Creating grub image memdisk.img"
  memdisktmp=$(mktemp -d)
  mkdir -p $memdisktmp/boot/grub
  cp boot/grub/memdisk_grub.cfg $memdisktmp/boot/grub/grub.cfg
  tar -C $memdisktmp -cf $memdisktmp/memdisk.tar boot
  echo "Creating grub image core.img"
  grub-mkimage -p /boot/grub -o /tmp/core.img -O i386-pc -m $memdisktmp/memdisk.tar \
    biosdisk iso9660 memdisk tar configfile loopback normal extcmd regexp test read echo
  echo "Prepending lnxboot.img to it"
  cat $GRUB_DIR/lnxboot.img /tmp/core.img > boot/g2l.img
  rm -r $memdisktmp /tmp/core.img
  echo "Creating salt.env"
  grub-editenv boot/grub/salt.env create
)
# remove uneeded/unwanted files
rm -rf boot/dos boot/isolinux boot/pxelinux.cfg boot/syslinux boot/bootinst.* boot/*.c32 boot/liloinst.sh
echo "Creating ISO..."
cd "$startdir"
#echo "pause"; read junk
xorriso -as mkisofs \
  -r \
  -J \
  -V "grub2_menu" \
  -A "grub2_menu" \
  -p "SaLT v$(cat ../version)" \
  -publisher "SaLT v$(cat ../version)" \
  -b $BOOTFILE \
  -c $CATALOGFILE \
  -isohybrid-mbr isohdpfx.bin \
  -partition_offset 16 \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -o "grub2menu.iso" \
  $ISODIR
rm -rf syslinux-$SYSLINUX_VER isohdpfx.bin
if [ -n "$QEMU" ]; then
  echo "Launching qemu..."
  qemu-system-i386 -m 256 -cdrom grub2menu.iso -boot order=d
  echo "Press a key to terminate..."
  read R
  rm -f grub2menu.iso
fi
rm -rf "$ISODIR" "$grubdir/build/boot/grub/"{locale,timezone,keymaps,lang.cfg,keyboard.cfg,timezone.cfg,bg.png,themes}

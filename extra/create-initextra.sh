#!/bin/sh
# vim: set syn=sh ai et sw=2 st=2 ts=2 tw=0:
#
# This file is part of SaLT.

cd $(dirname "$0")
if [ $UID -ne 0 ]; then
  echo 'Need to be root to run.' >&2
  exit 1
fi
COMP=$1
[ -z "$COMP" ] && COMP=xz
DEBUG=$2

BBVER=1.18.4
BBURL=http://busybox.net/downloads/busybox-$BBVER.tar.bz2
KERNELDIR=$PWD/../kernel

KVER=$KERNELDIR/lib/modules/*
KVER=$(echo $KVER | sed 's:.*/\([^/]\+\)$:\1:')
case $COMP in
  "gz")
    COMPCMD="gzip -9"
    ;;
  "xz")
    COMPCMD="xz --check=crc32"
    ;;
esac
# create the initial initrd
TREE=.initextra-tree
rm -rf $TREE
cp -a initextra-template $TREE
find $TREE -name '.svn' -type d -prune -exec rm -rf '{}' +
# adjust some rights
chown root:root $TREE
# get the previous initrd and copy the content to the template
sh ../create-initrd.sh $COMP $DEBUG
mkdir .initrd-tree
case $COMP in
  'gz')
    zcat ../initrd.gz > initrd
    ;;
  'xz')
    xzcat ../initrd.xz > initrd
    ;;
esac
mount -o loop initrd .initrd-tree
cp -r .initrd-tree/* $TREE
umount .initrd-tree
rm initrd ../initrd.$COMP
rmdir .initrd-tree
# download, compile and install busybox
if [ ! -e busybox-$BBVER.tar.bz2 ]; then
  wget $BBURL
fi
if [ ! -e busybox-$BBVER/_install/bin/busybox ]; then
  rm -rf busybox-$BBVER
  tar -xf busybox-$BBVER.tar.bz2
  (
    cd busybox-$BBVER
    cp ../bbconfig .config
    make
    make install
  )
fi
cp -av busybox-$BBVER/_install/bin/* $TREE/bin/
cp -av busybox-$BBVER/_install/sbin/* $TREE/sbin/
# copy needed modules
while read M; do
  if [ -e $KERNELDIR/lib/modules/$KVER/kernel/$M ]; then
    mkdir -p $TREE/lib/modules/$KVER/kernel/$(dirname $M)
    $COMPCMD < $KERNELDIR/lib/modules/$KVER/kernel/$M > $TREE/lib/modules/$KVER/kernel/$M.$COMP
  else
    if [ -z "$(grep kernel/$M $KERNELDIR/lib/modules/$KVER/modules.builtin)" ]; then
      echo "$M not found"
    else
      echo "$M is builtin"
    fi
  fi
done < modules
# create initextra.$COMP
INITEXTRA_SIZE_M=$('du' -sm $TREE|awk '{print $1}')
INITEXTRA_SIZE_M=$(($INITEXTRA_SIZE_M + 1))
rm -rf initextra initextra.$COMP initrd-ext2
dd if=/dev/zero of=initextra bs=1M count=$INITEXTRA_SIZE_M
mkfs.ext2 -m 0 -F -q initextra
mkdir initextra-ext2 && mount -o loop initextra initextra-ext2
cp -a $TREE/* initextra-ext2/
umount initextra-ext2 && rm -rf initextra-ext2
case $COMP in
  "gz")
    gzip initextra
    ;;
  "xz")
    xz --check=crc32 initextra
    ;;
esac

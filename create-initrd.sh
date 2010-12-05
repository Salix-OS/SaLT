#!/bin/sh
# vim: set syn=sh ai et sw=2 st=2 ts=2 tw=0:
cd $(dirname "$0")
if [ $UID -ne 0 ]; then
  echo 'Need to be root to run.' >&2
  exit 1
fi

BBVER=1.17.3
BBURL=http://busybox.net/downloads/busybox-$BBVER.tar.bz2
FILEVER=5.04
FILEURL=ftp://ftp.astron.com/pub/file/file-$FILEVER.tar.gz
KERNELDIR=$PWD/kernel

KVER=$KERNELDIR/lib/modules/*
KVER=$(echo $KVER | sed 's:.*/\([^/]\+\)$:\1:')
# create the initial initrd
TREE=.initrd-tree
rm -rf $TREE
cp -a initrd-template $TREE
find $TREE -name '.svn' -type d -exec -prune rm -rf '{}' +
# adjust some rights
chown root:root $TREE
mknod -m 0600 $TREE/dev/console c 5 1
mknod -m 0666 $TREE/dev/null c 1 3
mknod -m 0660 $TREE/dev/ram0 b 1 0
chown :6 $TREE/dev/ram0
mknod -m 0600 $TREE/dev/tty1 c 4 1
mknod -m 0600 $TREE/dev/tty2 c 4 2
# copy the configuration
cp config $TREE/etc/salt.cfg
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
# download, compile and install file
if [ ! -e file-$FILEVER.tar.gz ]; then
  wget $FILEURL
fi
if [ ! -e file-$FILEVER/src/file ]; then
  rm -rf file-$FILEVER
  tar -xf file-$FILEVER.tar.gz
  (
    cd file-$FILEVER
    ./configure \
      --prefix=/usr \
      --sysconfdir=/etc \
      --datadir=/etc \
      --enable-static=yes
    make
    cd src
    # static build is not working, we must do it manually.
    gcc -g -Os -static -o file file.o .libs/libmagic.a -lz
  )
fi
cp -av file-$FILEVER/src/file $TREE/bin/
mkdir -pv $TREE/etc/misc/magic
cp -rv file-$FILEVER/magic/Magdir/* $TREE/etc/misc/magic/
# copy needed modules
while read M; do
  if [ -e $KERNELDIR/lib/modules/$KVER/kernel/$M ]; then
    mkdir -p $TREE/lib/modules/$KVER/kernel/$(dirname $M)
    cp -v $KERNELDIR/lib/modules/$KVER/kernel/$M $TREE/lib/modules/$KVER/kernel/$M
  else
    if [ -z "$(grep kernel/$M $KERNELDIR/lib/modules/$KVER/modules.builtin)" ]; then
      echo "$M not found"
    else
      echo "$M is builtin"
    fi
  fi
done < modules
cp -a $KERNELDIR/lib/modules/$KVER/modules.{alias,builtin,dep,symbols} $TREE/lib/modules/$KVER/
# create initrd.gz
INITRD_SIZE_M=$('du' -sm $TREE|awk '{print $1}')
INITRD_SIZE_M=$(($INITRD_SIZE_M + 1))
rm -rf initrd initrd.gz initrd-ext2
dd if=/dev/zero of=initrd bs=1M count=$INITRD_SIZE_M
mkfs.ext2 -m 0 -F -q initrd
mkdir initrd-ext2 && mount -o loop initrd initrd-ext2
cp -a $TREE/* initrd-ext2/
umount initrd-ext2 && rm -rf initrd-ext2
gzip initrd

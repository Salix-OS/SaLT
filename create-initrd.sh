#!/bin/sh
# vim: set syn=sh ai et sw=2 st=2 ts=2 tw=0:
#
# This file is part of SaLT.

cd $(dirname "$0")
if [ "$(id -ru)" -ne 0 ]; then
  echo 'Need to be root to run.' >&2
  exit 1
fi
COMP=$1
[ -z "$COMP" ] && COMP=gz
DEBUG=$2

BBVER=1.18.5
BBURL=http://busybox.net/downloads/busybox-$BBVER.tar.bz2
FILEVER=5.06
FILEURL=ftp://ftp.astron.com/pub/file/file-$FILEVER.tar.gz
NTFS3GVER=2011.4.12
NTFS3GURL=http://tuxera.com/opensource/ntfs-3g_ntfsprogs-$NTFS3GVER.tgz
LSOFURL=ftp://ftp.fu-berlin.de/pub/unix/tools/lsof/lsof.tar.bz2
TIRPCURL=http://nfsv4.bullopensource.org/tarballs/tirpc/libtirpc-0.1.8-1.tar.bz2
KERNELDIR=$PWD/kernel

KVER=$KERNELDIR/lib/modules/*
KVER=$(echo $KVER | sed 's:.*/\([^/]\+\)$:\1:')
# create the initial initrd
TREE=.initrd-tree
rm -rf $TREE
cp -a initrd-template $TREE
find $TREE -name '.svn' -type d -prune -exec rm -rf '{}' +
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
# download, compile and install ntfs-3g (only needed binaries)
if [ ! -e ntfs-3g_ntfsprogs-$NTFS3GVER.tgz ]; then
  wget $NTFS3GURL
fi
if [ ! -e ntfs-3g_ntfsprogs-$NTFS3GVER/pkg/bin/ntfs-3g ]; then
  rm -rf ntfs-3g_ntfsprogs-$NTFS3GVER
  tar -xf ntfs-3g_ntfsprogs-$NTFS3GVER.tgz
  (
    cd ntfs-3g_ntfsprogs-$NTFS3GVER
    ./configure \
      --prefix=/usr \
      --enable-really-static \
      --disable-library \
      --disable-dependency-tracking \
      --disable-ntfsprogs
    make
    mkdir -p pkg
    make install DESTDIR=$PWD/pkg
  )
fi
cp -av ntfs-3g_ntfsprogs-$NTFS3GVER/pkg/bin/ntfs-3g $TREE/bin/
cp -av ntfs-3g_ntfsprogs-$NTFS3GVER/pkg/sbin/mount.ntfs-3g $TREE/sbin/
# download, compile and install lsof (only if debug)
if [ -n "$DEBUG" ]; then
  if [ ! -e lsof.tar.bz2 ]; then
    wget $LSOFURL
  fi
  if [ ! -e lsof_*/lsof_*_src/lsof ]; then
    rm -rf lsof_*
    tar -xf lsof.tar.bz2
    (
      cd lsof_*
      tar -xf lsof_*_src.tar
      cd lsof_*_src
      ./Configure -n linux
      # Determine glibc version
      glibcversion=$(readlink /lib/ld-linux.so*|sed 's/ld-\(.*\)\.so/\1/')
      if [ "$(echo -e "$glibcversion\n2.15"|sort -V|head -n1)" = "2.15" ]; then
        wget $TIRPCURL
        tar -xf libtirpc-*.tar.bz2
        rm libtirpc-*.tar.bz2
        mkdir tirpc
        tirpcdir=$PWD/tirpc
        cd libtirpc-*
        ./configure --prefix=/usr && make && make install DESTDIR=$tirpcdir
        rm -rf libtirpc-*
        sed -i "
          s:^CFGF=.*:\0 -I$tirpcdir/usr/include/tirpc -DHASNOTRPC -DHASNORPC_H:;
          s:^CFGL=.*:\0 -L$tirpcdir/usr/lib -ltirpc --static:;
          " Makefile
      else
        sed -i 's/^CFGL=.*/\0 --static/' Makefile
      fi
      make all
    )
  fi
  cp -av lsof_*/lsof_*_src/lsof $TREE/bin/
fi
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
cp -a $KERNELDIR/lib/modules/$KVER/modules.alias $TREE/lib/modules/$KVER/
cp -a $KERNELDIR/lib/modules/$KVER/modules.builtin $TREE/lib/modules/$KVER/
cp -a $KERNELDIR/lib/modules/$KVER/modules.dep $TREE/lib/modules/$KVER/
cp -a $KERNELDIR/lib/modules/$KVER/modules.symbols $TREE/lib/modules/$KVER/
# compress lib dir
(
  cd $TREE
  tar caf lib.tar.$COMP lib
  rm -rf lib
)
# create initrd.$COMP
INITRD_SIZE_M=$('du' -sm $TREE|awk '{print $1}')
INITRD_SIZE_M=$(($INITRD_SIZE_M + 1))
rm -rf initrd initrd.$COMP initrd-ext2
dd if=/dev/zero of=initrd bs=1M count=$INITRD_SIZE_M
mkfs.ext2 -m 0 -F -q initrd
mkdir initrd-ext2 && mount -o loop initrd initrd-ext2
cp -a $TREE/* initrd-ext2/
umount initrd-ext2 && rm -rf initrd-ext2
case $COMP in
  "gz")
    gzip initrd
    ;;
  "xz")
    xz --check=crc32 initrd
    ;;
esac

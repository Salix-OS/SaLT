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
HTTPFSVER=0.1.4

BBURL=http://busybox.net/downloads/busybox-$BBVER.tar.bz2
SSHFSBIN=/usr/bin/sshfs
SSHBIN=/usr/bin/ssh
CURLFTPFSBIN=/usr/bin/curlftpfs
HTTPFSURL=http://sourceforge.net/projects/httpfs/files/httpfs2/httpfs2-$HTTPFSVER.tar.gz/download
CIFSBINS=(/usr/sbin/mount.cifs /usr/sbin/umount.cifs)
EXTRALIBS="/lib/libnss_*"
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
chown -R root:root $TREE
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
(
  cd $TREE
  tar xf lib.tar.*
  rm lib.tar.*
)
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
# busybox is dynamically linked agains glibc, so include it
for l in $(ldd $TREE/bin/busybox | cut -d'>' -f2 | cut -d'(' -f1); do
  l2="$l"
  while [ -h "$l2" ]; do
    cp -Pv "$l2" $TREE/lib/
    l2=$(readlink -f "$l2")
  done
  cp -Pv "$l2" $TREE/lib/
done
# copy curlftpfs on the initrd using the one installed in the distro.
cp $CURLFTPFSBIN $TREE/bin/
for l in $(ldd $CURLFTPFSBIN | cut -d'>' -f2 | cut -d'(' -f1); do
  l2="$l"
  while [ -h "$l2" ]; do
    cp -Pv "$l2" $TREE/lib/
    l2=$(readlink -f "$l2")
  done
  cp -Pv "$l2" $TREE/lib/
done
# copy sshfs on the initrd using the one installed in the distro.
cp $SSHFSBIN $TREE/bin/
for l in $(ldd $SSHFSBIN | cut -d'>' -f2 | cut -d'(' -f1); do
  l2="$l"
  while [ -h "$l2" ]; do
    cp -Pv "$l2" $TREE/lib/
    l2=$(readlink -f "$l2")
  done
  cp -Pv "$l2" $TREE/lib/
done
# copy ssh on the initrd using the one installed in the distro.
cp $SSHBIN $TREE/bin/
for l in $(ldd $SSHBIN | cut -d'>' -f2 | cut -d'(' -f1); do
  l2="$l"
  while [ -h "$l2" ]; do
    cp -Pv "$l2" $TREE/lib/
    l2=$(readlink -f "$l2")
  done
  cp -Pv "$l2" $TREE/lib/
done
for l in ${CIFSBINS[*]}; do
  l2="$l"
  while [ -h "$l2" ]; do
    cp -Pv "$l2" $TREE/lib/
    l2=$(readlink -f "$l2")
  done
  cp -Pv "$l2" $TREE/lib/
done
for l in ${EXTRALIBS[*]}; do
  l2="$l"
  while [ -h "$l2" ]; do
    cp -Pv "$l2" $TREE/lib/
    l2=$(readlink -f "$l2")
  done
  cp -Pv "$l2" $TREE/lib/
done
chmod +x $TREE/lib/*.so.*
# download, compile and install httpfs
if [ ! -e httpfs2-$HTTPFSVER.tar.gz ]; then
  wget $HTTPFSURL
fi
if [ ! -e httpfs2-$HTTPFSVER/httpfs2 ]; then
  rm -rf httpfs2-$HTTPFSVER
  tar -xf httpfs2-$HTTPFSVER.tar.gz
  (
    cd httpfs2-$HTTPFSVER
    make
  )
fi
cp -av httpfs2-$HTTPFSVER/httpfs2 $TREE/bin/
# /etc stuff
mkdir -p $TREE/etc
echo 'root:x:0:0:root:/:/bin/sh' > $TREE/etc/passwd
echo 'root:x:0:root' > $TREE/etc/group
echo 'root:!:9797:0:::::' > $TREE/etc/shadow
# copy needed modules
echo "Finding modules..."
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
# adjust some rights
chown -R root:root $TREE
# compress lib dir
(
  cd $TREE
  excludes=$(mktemp)
  'ls' -1 lib/ld-* lib/libc.* lib/libc-* > $excludes
  tar cavf lib.tar.$COMP -X $excludes lib
  rm -f $excludes
  unset excludes
  mv lib lib2
  mkdir lib
  mv lib2/ld-* lib2/libc.* lib2/libc-* lib/
  rm -rf lib2
)
# compress non busybox binaries in usr/bin
for f in $(find $TREE/usr/bin -type f | grep -v 'busybox'); do
  xz < $f > $f.xz
  rm $f
done
# compress etc/misc
(
  cd $TREE/etc
  tar cavf misc.tar.xz misc
  rm -rf misc
)

# create initrd initextra.$COMP
INITEXTRA_SIZE_M=$('du' -sm $TREE|awk '{print $1}')
INITEXTRA_SIZE_M=$(($INITEXTRA_SIZE_M + 1))
SIZE_MAX=$(grep '^CONFIG_BLK_DEV_RAM_SIZE=' ../kernel/boot/config* | cut -d= -f2)
SIZE_MAX=$(($SIZE_MAX / 1024))
if [ $INITEXTRA_SIZE_M -gt $SIZE_MAX ]; then
  echo "initrd size needs ${INITEXTRA_SIZE_M}MB, but the kernel only supports ${SIZE_MAX}MB."
  exit 1
else
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
fi

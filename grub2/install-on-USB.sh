#!/bin/sh
cd $(dirname $0)

VER=1.5
AUTHOR='Pontvieux Cyrille - jrd@enialis.net'
LICENCE='GPL v3+'
SCRIPT="$(basename "$0")"
SCRIPT="$(readlink -f "$SCRIPT")"

version() {
  echo "install-on-USB v$VER by $AUTHOR"
  echo "Licence : $LICENCE"
  echo '-> Install grub2(+syslinux) on an USB key using an ISO or the USB key itself.'
}

usage() {
  version
  echo ''
  echo 'usage: install-on-USB.sh [-h/--help] [-v/--version]'
  exit 1
}

get_mnt_dir() {
  # sort reverse order so we try submounts first
  mounts=$(mount | sed -e 's/^.* on \(.*\) type.*$/\1/' | sort -dur)
  startdir=$PWD
  unset mntdir
  while [ "$PWD" != "/" ]; do
    for m in $mounts; do
      if [ "$PWD" == "$m" ]; then
        echo $m
        cd $startdir
        return
      fi
    done
    cd ..
  done
  # should never reach here
  echo "Error: Could not find mountpoint for: $startdir"
  exit 2
}

get_dev_part() {
  MNTDIR="$1"
  DEVPART=$(mount | grep "on $MNTDIR " | cut -d' ' -f1 | head -n 1)
  if [ -z "$DEVPART" ]; then
    echo "Error: $MNTDIR doesn't seem to be mounted" >&2
    exit 2
  elif ([ "$(echo $DEVPART | awk '{s=substr($1, 1, 1); print s;}')" != "/" ] || [ ! -r "$DEVPART" ] || [ ! -b "$DEVPART" ]); then
    echo "Error: $DEVPART detected as a the device of" >&2
    echo "  $MNTDIR but seems invalid." >&2
    exit 2
  fi
  echo $DEVPART
}

get_partition_num() {
  DEVPART="$1"
  echo $DEVPART|sed 's/^.*[^0-9]\([0-9]*\)$/\1/'
}

get_dev_root() {
  DEVPART="$1"
  PARTNUM="$2"
  DEVROOT=$(echo $DEVPART|sed "s/$PARTNUM\$//")
  if ([ "$(echo $DEVROOT | awk '{s=substr($1, 1, 1); print s;}')" != "/" ] || [ ! -r "$DEVROOT" ] || [ ! -b "$DEVROOT" ]); then
    echo "Error: $DEVROOT detected as a the root device of" >&2
    echo "  $DEVPART but seems invalid." >&2
    exit 2
  fi
  echo $DEVROOT
}

install_syslinux() {
  DIR="$1"
  DEVICE="$2"
  DEVPART="$3"
  PARTNUM="$4"
  BASEDIR="$5"
  img="$DIR/${BASEDIR}boot/grub2-linux.img"
  relimg="${BASEDIR}boot/grub2-linux.img"
  if ! [ -f "$img" ]; then
    echo "Error: Could not find the image file: $img"
    exit 2
  fi
  which syslinux >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: syslinux is not available on your system." >&2
    echo "  Installation on your USB key is therefore impossible." >&2
    exit 2
  fi
  which parted >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: parted is not available on your system." >&2
    echo "  Installation on your USB key is therefore impossible." >&2
    exit 2
  fi
  echo "Warning: syslinux+grub2 is about to be installed in $DEVICE"
  # check if we hit an unpartitioned stick e.g. fat fs directly on
  # /dev/sdc without /dev/sdc1
  if [ "$DEVPART" != "$DEVICE" ]; then
    echo "on partition $DEVPART"
  fi
  printf "Do you want to continue? [y/N] "
  read R
  if ([ "$R" = "y" ] || [ "$R" = "Y" ]); then
    signature="$(dd if=$DEVICE bs=1 count=2 skip=510 2>/dev/null | od -t x1 | tr '\n' ' ')"
    if [ "$signature" != "0000000 55 aa 0000002 " ]; then
      # no valid mbr magic 0x55 0xAA
      echo "Error: $DEVICE does not contain a valid MBR."
      echo "For safety reasons we won't install to such a media."
      exit 3
    fi
    bakfile="$DIR/${BASEDIR}boot/"$(echo $DEVICE|tr '/' '_').mbr.$(date +%Y%m%d%H%M)
    echo "Backing up mbr of $DEVICE to '$bakfile'..."
    dd if=$DEVICE of="$bakfile" bs=512 count=1
    echo "Installing syslinux..."
    syslinux $DEVPART
    if [ "$DEVPART" != "$DEVICE" ]; then
      echo  "Do you want to overwrite the MBR loader (first 440 bytes)"
      echo "of the disk? Recommended unless you know the code in there"
      printf "already does what you want. [y/N] "
      read R
      if ([ "$R" = "y" ] || [ "$R" = "Y" ]); then
        # this makes parted write a mbr loader
        dd if=/dev/zero of=$DEVICE bs=1 count=1
      fi
      echo "Setting bootable flag of $DEVPART..."
      parted $DEVICE set $PARTNUM boot on
    fi
    sync
    cat <<EOF > "$DIR"/syslinux.cfg
DEFAULT grub2
PROMPT 0
NOESCAPE 1
TOTALTIMEOUT 1
ONTIMEOUT grub2
LABEL grub2
  SAY Chainloading to grub2...
  LINUX $relimg
EOF
  fi
}

run_as_root() {
  if which gksu >/dev/null 2>&1; then
    exec gksu "$@"
  else
    exec "$@" # will fail
  fi
}

# check if we are run non-interactive (e.g. from file manager)
if [ ! -t 0 ]; then
  CMD="/bin/sh -c '$SCRIPT; echo Press enter to exit; read;'"
  if which xterm >/dev/null 2>&1; then
    run_as_root xterm -e $CMD
  fi
fi

if ([ "$1" = "--version" ] || [ "$1" = "-v" ]); then
  version
  exit 0
fi
if ([ "$1" = "--help" ] || [ "$1" = "-h" ]); then
  usage
fi
if [ $(id -ru) -ne 0 ]; then
  echo "Error : you must run this script as root" >&2
  exit 2
fi
MNTDIR=$(get_mnt_dir)
if [ ! -f "$MNTDIR/"*.live ]; then
  echo "Error: You need to put the .live file from the iso into the root of the usb key $MNTDIR"
  exit 2
fi
BASEDIR=$(cd ..; echo $PWD | sed -e "s:$MNTDIR::" -e "s:^/::")
if [ -n "$BASEDIR" ]; then
	BASEDIR="$BASEDIR/"
fi
DEVPART=$(get_dev_part "$MNTDIR"); [ $? -ne 0 ] && exit $?
PARTNUM=$(get_partition_num "$DEVPART"); [ $? -ne 0 ] && exit $?
DEVROOT=$(get_dev_root "$DEVPART" "$PARTNUM"); [ $? -ne 0 ] && exit $?
install_syslinux "$MNTDIR" $DEVROOT $DEVPART $PARTNUM "$BASEDIR"
exit 0

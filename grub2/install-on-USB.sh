#!/bin/sh
cd $(dirname $0)

VER=1.4
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
    bakfile="$DIR"/boot/$(echo $DEVICE|tr '/' '_').mbr.$(date +%Y%m%d%H%m)
    echo "Backing up mbr of $DEVICE to '$bakfile'..."
    dd if=$DEVICE of=$bakfile bs=512 count=1
    echo "Installing syslinux..."
    syslinux $DEVPART
    if [ "$DEVPART" != "$DEVICE" ]; then
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
  LINUX boot/grub2-linux.img
EOF
  fi
}

run_as_root() {
  if which gksu >/dev/null 2>&1; then
    exec gksu $@
  fi
}

# check if we are run non-interactive (e.g. from file manager)
if [ ! -t 0 ]; then
  CMD="/bin/sh '$SCRIPT; echo Press enter to exit; read;'"
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
if [ "$(id -ru)" -ne "0" ]; then
  echo "Error : you must run this script as root" >&2
  exit 2
fi
MNTDIR=$(cd ..; echo "$PWD")
DEVPART=$(get_dev_part "$MNTDIR"); [ $? -ne 0 ] && exit $?
PARTNUM=$(get_partition_num "$DEVPART"); [ $? -ne 0 ] && exit $?
DEVROOT=$(get_dev_root "$DEVPART" "$PARTNUM"); [ $? -ne 0 ] && exit $?
install_syslinux "$MNTDIR" $DEVROOT $DEVPART $PARTNUM
exit 0

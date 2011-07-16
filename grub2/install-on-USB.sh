#!/bin/sh
cd $(dirname $0)

VER=1.4
AUTHOR='Pontvieux Cyrille - jrd@enialis.net'
LICENCE='GPL v3+'

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

get_dev_root() {
  MNTDIR="$1"
  DEVPART=$(mount | grep "on $MNTDIR " | cut -d' ' -f1 | head -n 1)
  if [ -z "$DEVPART" ]; then
    echo "Error: $MNTDIR doesn't seem to be mounted" >&2
    exit 2
  elif ([ "$(echo $DEVPART | awk '{s=substr($1, 1, 1); print s;}')" != "/" ] || [ ! -r "$DEVPART" ]); then
    echo "Error: $DEVPART detected as a the device of" >&2
    echo "  $MNTDIR but seems invalid." >&2
    exit 2
  else
    echo $DEVPART | awk -v l=${#DEVPART} '{s=substr($1, 1, l - 1); print s;}'
  fi
}

get_partition_num() {
  MNTDIR="$1"
  DEVPART=$(mount | grep "on $MNTDIR " | cut -d' ' -f1 | head -n 1)
  if [ -z "$DEVPART" ]; then
    echo "Error: $MNTDIR doesn't seem to be mounted" >&2
    exit 2
  elif ([ "$(echo $DEVPART | awk '{s=substr($1, 1, 1); print s;}')" != "/" ] || [ ! -r "$DEVPART" ]); then
    echo "Error: $DEVPART detected as a the device of" >&2
    echo "  $MNTDIR but seems invalid." >&2
    exit 2
  else
    echo $DEVPART|sed 's/^.*[^0-9]\([0-9]\+\)$/\1/'
  fi
}

install_syslinux() {
  DIR="$1"
  DEVICE="$2"
  PARTNUM="$3"
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
  printf "Do you want to continue? [y/N] "
  read R
  if ([ "$R" = "y" ] || [ "$R" = "Y" ]); then
    syslinux $DEVICE$PARTNUM
    parted $DEVICE set $PARTNUM boot on
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
DEVROOT=$(get_dev_root "$MNTDIR"); [ $? -ne 0 ] && exit $?
PARTNUM=$(get_partition_num "$MNTDIR"); [ $? -ne 0 ] && exit $?
install_syslinux "$MNTDIR" $DEVROOT $PARTNUM
exit 0

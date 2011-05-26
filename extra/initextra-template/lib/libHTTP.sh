#!/bin/sh
# vim: set syn=sh ai si et sw=2 st=2 ts=2 tw=0:
#
# This file is part of SaLT.
# Copyright: Cyrille Pontvieux <jrd@salixos.org>
# Licence: GPLv3+
# Extra initial script sourced by the "init" script

# load the SaLT library
. /lib/libSaLT

infolog 'Loading data through HTTP...'
RSERVER="$1"
RPORT="$2"
RPATH="$3"
ISOFILE=$(basename "$RPATH")
MP1=/mnt/http
MP=/mnt/iso
d=http://$RSERVER
[ -n "$RPORT" ] && d=$d:$RPORT
d=$d$RPATH
MNTCMD="httpfs2 -c /dev/null $d $MP1"

mkdir -p $MP1 $MP
$($MNTCMD)
OK=$?
if [ $OK -eq 0 ]; then
  if [ -e "$MP1/$ISOFILE" ]; then
    mount -o loop "$MP1/$ISOFILE" $MP
    OK=$?
    if [ $OK -eq 0 ]; then
      echo "$MP:$d" > /tmp/distro_infos
    fi
  else
    umount $MP1
    OK=1
  fi
fi
if [ $OK -ne 0 ]; then
  rmdir $MP1 $MP
fi
debugshell

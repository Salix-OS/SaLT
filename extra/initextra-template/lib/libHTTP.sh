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
echoinfo " * Connecting to $d..."
$($MNTCMD)
OK=$?
if [ $OK -eq 0 ]; then
  if [ -e "$MP1/$ISOFILE" ]; then
    file "$MP1/$ISOFILE" | grep -q 'ISO 9660 CD-ROM filesystem data'
    if [ $? -eq 0 ]; then
      mount -o loop "$MP1/$ISOFILE" $MP
      OK=$?
      if [ $OK -eq 0 ]; then
        echodebug "HTTP ISO mounted in $MP"
        echo "$MP:$d" > /tmp/distro_infos
      else
        echoerror "HTTP mounted, ISO file $ISOFILE found, but cannot mount it"
      fi
    else
      echoerror "HTTP mounted but ISO file $ISOFILE is not an cdrom iso"
    fi
  else
    echoerror "HTTP mounted but ISO file $ISOFILE not found"
    umount $MP1
    OK=1
  fi
fi
if [ $OK -ne 0 ]; then
  echoerror "HTTP mount failed"
  rmdir $MP1 $MP
fi
debugshell

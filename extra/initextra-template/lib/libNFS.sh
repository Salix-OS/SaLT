#!/bin/sh
# vim: set syn=sh ai si et sw=2 st=2 ts=2 tw=0:
#
# This file is part of SaLT.
# Copyright: Cyrille Pontvieux <jrd@salixos.org>
# Licence: GPLv3+
# Extra initial script sourced by the "init" script

# load the SaLT library
. /lib/libSaLT

infolog 'Loading data through NFS...'
RSERVER="$1"
RPORT="$2"
RPATH="$3"
MP=/mnt/nfs
d=nfs://$RSERVER
[ -n "$RPORT" ] && d=$d:$RPORT
d=$d:$RPATH
MNTCMD="mount -t nfs -o nolock,ro,rsize=8192,wsize=8192,retry=0"
MNTCMDtest="$MNTCMD,timeo=10"
[ -n "$RPORT" ] && MNTCMD="$MNTCMD,port=$RPORT"
[ -n "$RPORT" ] && MNTCMDtest="$MNTCMDtest,port=$RPORT"
MNTCMD="$MNTCMD $RSERVER:$RPATH $MP"
MNTCMDtest="$MNTCMDtest $RSERVER:$RPATH $MP"

modprobe_check nfs
mkdir -p $MP
echoinfo " * Connecting to $d..."
$($MNTCMDtest)
if [ $? -eq 0 ]; then
  umount "$MP"
  $($MNTCMD)
  echodebug "NFS mounted in $MP"
  echo "$MP:$d" > /tmp/distro_infos
else
  echoerror "NFS mount failed"
  rmdir $MP
fi
debugshell

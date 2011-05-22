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
RUSER="$3"
RPATH="$4"
MP=/mnt/ssh
d=ssh://$RUSER@$RSERVER
[ -n "$RPORT" ] && d=$d:$RPORT
d=$d:$RPATH
MNTCMD="sshfs $RUSER@$RSERVER:$RPATH"
[ -n "$RPORT" ] && MNTCMD="$MNTCMD -p $RPORT"

mkdir -p $MP
$($MNTCMD)
if [ $? -eq 0 ]; then
  echo "$MP:$d" > /tmp/distro_infos
else
  rmdir $MP
fi
debugshell

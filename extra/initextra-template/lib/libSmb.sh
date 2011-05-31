#!/bin/sh
# vim: set syn=sh ai si et sw=2 st=2 ts=2 tw=0:
#
# This file is part of SaLT.
# Copyright: Cyrille Pontvieux <jrd@salixos.org>
# Licence: GPLv3+
# Extra initial script sourced by the "init" script

# load the SaLT library
. /lib/libSaLT

infolog 'Loading data through Samba...'
RSERVER="$1"
RUSER="$2"
RPWD="$3"
RPATH="$4"
MP=/mnt/samba
d=smb://
if [ -n "$RUSER" ]; then
  d="$d$RUSER"
  [ -n "$RPWD" ] && d="$d:$RPWD"
  d="$d@"
fi
d=$d$RSERVER/$RPATH
MNTCMD="mount -t cifs"
if [ -n "$RUSER" ]; then
  echo "username=$RUSER" > /.creds
  chmod go-rw /.creds
  if [ -n "$RPWD" ]; then
    echo "password=$PWD" >> /.creds
  fi
  MNTCMD="$MNTCMD -o credentials=/.creds"
else
  MNTCMD="$MNTCMD -o guest"
fi
MNTCMD="$MNTCMD //$RSERVER/$RPATH $MP"

modprobe_check cifs
mkdir -p $MP
echoinfo " * Connecting to $d..."
$($MNTCMD)
if [ $? -eq 0 ]; then
  echodebug "Samba mounted in $MP"
  echo "$MP:$d" > /tmp/distro_infos
else
  echoerror "Samba mount failed"
  rmdir $MP
fi
debugshell

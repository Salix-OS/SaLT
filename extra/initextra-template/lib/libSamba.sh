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
d=samba://
if [ -n "$RUSER" ]; then
  d="$d$RUSER"
  [ -n "$RPWD" ] && d="$d:$RPWD"
  d="$d@"
fi
d=$d$RSERVER/$RPATH
MNTCMD="mount -t cifs"
if [ -n "$RUSER" ]; then
  mkdir -p /root
  echo "username=$RUSER" > /root/.creds
  chmod go-rw /root/.creds
  if [ -n "$RPWD" ]; then
    echo "password=$PWD" >> /root/.creds
  fi
  MNTCMD="$MNTCMD -o credentials=/root/.creds"
else
  MNTCMD="$MNTCMD -o guest"
fi
MNTCMD="$MNTCMD //$RSERVER/$RPATH $MP"

modprobe_check cifs
mkdir -p $MP
$($MNTCMD)
if [ $? -eq 0 ]; then
  echo "$MP:$d" > /tmp/distro_infos
else
  rmdir $MP
fi
debugshell

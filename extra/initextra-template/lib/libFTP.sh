#!/bin/sh
# vim: set syn=sh ai si et sw=2 st=2 ts=2 tw=0:
#
# This file is part of SaLT.
# Copyright: Cyrille Pontvieux <jrd@salixos.org>
# Licence: GPLv3+
# Extra initial script sourced by the "init" script

# load the SaLT library
. /lib/libSaLT

infolog 'Loading data through FTP...'
RSERVER="$1"
RPORT="$2"
RUSER="$3"
RPWD="$4"
RPATH="$5"
MP=/mnt/ftp
d=ftp://$RSERVER
[ -n "$RPORT" ] && d=$d:$RPORT
d=$d$RPATH
if [ -n "$RUSER" ]; then
  mkdir -p /root
  echo "machine $RSERVER" > /root/.netrc
  chmod go-rw /root/.netrc
  echo "login $RUSER" >> /root/.netrc
  if [ -n "$RPWD" ]; then
    echo "password $PWD" >> /root/.netrc
  fi
fi
MNTCMD="curlftpfs $d $MP"

mkdir -p $MP
$($MNTCMD)
if [ $? -eq 0 ]; then
  echo "$MP:$d" > /tmp/distro_infos
else
  rmdir $MP
fi
debugshell

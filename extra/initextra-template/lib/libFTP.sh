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
d=$d/$RPATH
if [ -n "$RUSER" ]; then
  echo "machine $RSERVER" > /.netrc
  chmod go-rw /.netrc
  echo "login $RUSER" >> /.netrc
  if [ -n "$RPWD" ]; then
    echo "password $RPWD" >> /.netrc
  fi
fi
MNTCMD="curlftpfs $d $MP"

mkdir -p $MP
# curlftpfs relies on /etc/mtab, so we should use /proc/mounts for it.
mv /etc/mtab /etc/mtab.bak
(cd /etc; ln -s /proc/mounts mtab)
echoinfo " * Connecting to $d..."
$($MNTCMD)
if [ $? -eq 0 ]; then
  echodebug "FTP mounted in $MP"
  echo "$MP:$d" > /tmp/distro_infos
else
  echoerror "FTP mount failed"
  rmdir $MP
fi
# restore the real /etc/mtab.
rm /etc/mtab; mv /etc/mtab.bak /etc/mtab
debugshell

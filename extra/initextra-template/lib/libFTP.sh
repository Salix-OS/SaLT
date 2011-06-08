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

ISOFILE=$(basename "$RPATH")
MP=/mnt/iso
d=ftp://$RSERVER
url=ftp://
if [ -n "$RUSER" ]; then
  url="$url$RUSER"
  if [ -n "$RPWD" ]; then
    url="$url:$RPWD"
  fi
  url="$url@"
fi
url="$url$RSERVER"
[ -n "$RPORT" ] && d=$d:$RPORT
[ -n "$RPORT" ] && url="$url:$RPORT"
d=$d$RPATH
url="$url$RPATH"
MNTCMD="wget -O /tmp/distrolive.iso $url"

mkdir -p $MP
echoinfo " * Downloading from $d..."
$($MNTCMD)
OK=$?
if [ $OK -eq 0 ]; then
  if [ -e /tmp/distrolive.iso ]; then
    file /tmp/distrolive.iso | grep -q 'ISO 9660 CD-ROM filesystem data'
    if [ $? -eq 0 ]; then
      mount -o loop /tmp/distrolive.iso $MP
      OK=$?
      if [ $OK -eq 0 ]; then
        echodebug "FTP ISO mounted in $MP"
        echo "$MP:$d" > /tmp/distro_infos
      else
        echoerror "FTP mounted, ISO file $ISOFILE found, but cannot mount it"
      fi
    else
      echoerror "FTP mounted but ISO file $ISOFILE is not an cdrom iso"
    fi
  else
    echoerror "FTP mounted but file /tmp/distrolive.iso not found"
    OK=1
  fi
fi
if [ $OK -ne 0 ]; then
  echoerror "FTP mount failed"
  rm -f /tmp/distrolive.iso
  rmdir $MP
fi

# curlftpfs is not working with chroot
# MP=/mnt/ftp
# d=ftp://$RSERVER
# [ -n "$RPORT" ] && d=$d:$RPORT
# d=$d/$RPATH
# if [ -n "$RUSER" ]; then
#   echo "machine $RSERVER" > /.netrc
#   chmod go-rw /.netrc
#   echo "login $RUSER" >> /.netrc
#   if [ -n "$RPWD" ]; then
#     echo "password $RPWD" >> /.netrc
#   fi
# fi
# MNTCMD="curlftpfs $d $MP"
#
#
# mkdir -p $MP
# # curlftpfs relies on /etc/mtab, so we should use /proc/mounts for it.
# mv /etc/mtab /etc/mtab.bak
# (cd /etc; ln -s /proc/mounts mtab)
#echoinfo " * Connecting to $d..."
#$($MNTCMD)
#if [ $? -eq 0 ]; then
#  echodebug "FTP mounted in $MP"
#  echo "$MP:$d" > /tmp/distro_infos
#else
#  echoerror "FTP mount failed"
#  rmdir $MP
#fi
# # restore the real /etc/mtab.
# rm /etc/mtab; mv /etc/mtab.bak /etc/mtab

debugshell

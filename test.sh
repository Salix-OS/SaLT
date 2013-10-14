#!/bin/sh
cd $(dirname "$0")
rm -rf overlay/*
(
  cd overlay
  mkdir -p bashonly salixlive/modules
  cd bashonly
  mkdir -p sbin etc usr/share
  cp /sbin/init sbin/
  ln -s mnt/salt/bin bin
  cat <<'EOF' > .profile
mount -o remount,rw /
for f in reboot halt poweroff; do (cd sbin && ln -s ../mnt/salt/cleanup $f); done
echo
echo "* SaLT version $(cat /mnt/salt/salt-version)"
echo
EOF
  cat <<'EOF' > etc/inittab
# Default runlevel.
id:3:initdefault:
# System initialization (runs when system boots).
si:S:sysinit:/bin/bash -l
EOF
  cp -r /usr/share/zoneinfo usr/share/
  cd ..
  mksquashfs bashonly salixlive/modules/bashonly.salt -all-root
)
gksu "bash -c './create-iso.sh -t grub2/themes/Shine -k \"$PWD\"/kernelive-*.txz && chown $USER: salt.iso'"
rm -r overlay/*

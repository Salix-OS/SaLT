#!/bin/sh
[ $UID -eq 0 ] || exit 1
cd $(dirname $0)
./create-initrd.sh && cp kernel/boot/vmlinuz-* iso/isolinux/vmlinuz && cp initrd.gz iso/isolinux/initrd.gz && mkisofs -R -J -V SaLT -b isolinux/isolinux.bin -c isolinux/isolinux.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o salt.iso iso && chown jrd:users salt.iso 

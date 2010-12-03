#!/bin/sh
cd $(dirname $0)
[ "$1" = "debug" ] && debug=debug || debug=
./create-initrd.sh && cp kernel/boot/vmlinuz-* iso/isolinux/vmlinuz && cp initrd.gz iso/isolinux/initrd.gz && sed -i "s:\(.*/dev/ram0\).*:\1 $debug:" iso/isolinux/isolinux.cfg && mkisofs -R -J -V SaLT -b isolinux/isolinux.bin -c isolinux/isolinux.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o salt.iso iso

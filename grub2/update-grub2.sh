#!/bin/sh
cd "$(dirname "$0")"
which grub-mkimage >/dev/null 2>&1
if [ $? -eq 0 ]; then
  if [ -d grub/i386-pc ]; then
    touch grub2-core.img 2>/dev/null
    if [ $? -eq 0 ]; then
      GRUB2_IDENT_FILE="$(grub-mkimage -V | cut -d' ' -f2- | tr -d '()\n' | tr ' ' '_')-$(date +%Y%m%d-%H%M)"
      sed -i "s:\(set grub2_ident_file_path\)=.*:\1=$GRUB2_IDENT_FILE:" grub/embed.cfg
      echo "DO NOT REMOVE THIS FILE. It helps grub2 find its root device when chainloaded." > grub/$GRUB2_IDENT_FILE
      grub-mkimage -d grub/i386-pc -p /boot/grub/i386-pc -o grub2-core.img -O i386-pc -C none -c grub/embed.cfg biosdisk ext2 fat iso9660 ntfs reiserfs xfs part_msdos part_gpt search echo
      cat grub/i386-pc/lnxboot.img grub2-core.img grub2-linux.img
      cat grub/i386-pc/g2hdr.img grub2-core.img g2ldr
      rm -f grub2-core.img
    else
      echo "This script should be run from a writable media." >&2
      exit 3
    fi
  else
    echo "grub/i386-pc: folder not found." >&2
    echo "This script should be run from the boot directory of a SaLT Live USB Key." >&2
    exit 2
  fi
else
  echo "grub-mkimage should be available to update grub2." >&2
  exit 1
fi

#!/bin/sh
cd $(dirname "$0")
mkdir -p overlay/test/root overlay/test/var/log/setup/tmp overlay/salixlive/modules
cat <<'EOF' > overlay/test/root/.profile
echo
echo "* SaLT version $(cat /mnt/salt/salt-version) - Test ISO"
echo
EOF
for p in test/*.t?z; do
  echo "$p..."
  tar -C overlay/test -xf $p
  if [ -e overlay/test/install/doinst.sh ]; then
    (cd overlay/test && sh install/doinst.sh -install)
  fi
  [ -e overlay/test/install ] && rm -rf overlay/test/install
done
rootpwd=$(python -c "
import crypt
import string
import random
print crypt.crypt('live', '\$1\$'+''.join([random.choice(string.letters + string.digits + './') for c in range(8)])+'\$')
")
sed -i "/^root/ s,^root::,root:$rootpwd:," overlay/test/etc/shadow
mksquashfs overlay/test overlay/salixlive/modules/test.salt -comp xz -no-exports -no-xattrs -noappend
rm -rf overlay/test
cat <<'EOF' > overlay.sh && chmod +x overlay.sh
#!/bin/sh
D=$1
sed -i '/salt_runlevel=/ { s/=.*/=3/ }' $D/boot/grub/defaults.cfg
EOF
./create-iso.sh -t grub2/themes/Shine -k "$PWD"/test/kernelive-*.txz
rm -rf overlay/* overlay.sh

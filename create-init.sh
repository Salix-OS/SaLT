#!/bin/sh
VER=2.88dsf
URL="http://download.savannah.gnu.org/releases/sysvinit/sysvinit-$VER.tar.bz2"
PATCH_SLACK="http://salix.enialis.net/i486/slackware-14.0/source/a/sysvinit/sysvinit.paths.diff.gz"
PATCH_EXEC="http://savannah.nongnu.org/bugs/download.php?file_id=23518"
cd $(dirname "$0")
[ -e src-init/init ] && exit 0
mkdir -p src-init
(
  cd src-init
  wget "$URL" || exit 1
  tar xf sysvinit-$VER.tar.bz2 || exit 1
  wget "$PATCH_SLACK" || exit 1
  wget -O sysvinit.exec.patch "$PATCH_EXEC" || exit 1
  (
    cd sysvinit-$VER
    zcat ../sysvinit.paths.diff.gz | patch -p0 || exit 1
    cat ../sysvinit.exec.patch | patch -p0 || exit 1
    sed -i 's/^STATIC[ \t]=.*/STATIC = -static/' src/Makefile || exit 1
    (cd src && make clobber && make init) || exit 1
  )
  [ -e sysvinit-$VER/src/init ] && cp sysvinit-$VER/src/init .
)

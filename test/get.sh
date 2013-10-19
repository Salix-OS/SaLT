#!/bin/sh
cd $(dirname "$0")
cat <<EOF > slapt-getrc
WORKINGDIR=$PWD
EXCLUDE=-x86_64-
SOURCE=http://salix.enialis.net/i486/slackware-14.0/:OFFICIAL
SOURCE=http://salix.enialis.net/i486/slackware-14.0/extra/:OFFICIAL
SOURCE=http://salix.enialis.net/i486/14.0/:PREFERRED
EOF
/usr/sbin/slapt-get -c slapt-getrc -u
wget -c $(/usr/sbin/slapt-get -c slapt-getrc -i -d -y --reinstall --print-uris --no-md5 --no-dep $(cat lst) | grep ^http)
rm -rf slapt-getrc package_data .http*

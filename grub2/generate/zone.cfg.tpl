# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
if [ -z "$included" ]; then
  source $cfgprefix/include.cfg
fi
initmenu
# next config file to load
function nextconfig {
  configfile $cfgprefix/timezone/$salt_timezone.cfg
}
function skipnextconfig {
  configfile $cfgprefix/boot.cfg
}
menuentry "UTC" {
  set salt_timezone="UTC"
  set salt_hwclock="UTC"
  skipnextconfig
}

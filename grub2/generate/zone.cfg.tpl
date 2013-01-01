# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
source $cfgprefix/include.cfg
initmenu
# next config file to load
function nextconfig {
  configfile $cfgprefix/timezone/$timezone.cfg
}
function skipnextconfig {
  configfile $cfgprefix/boot.cfg
}
menuentry "UTC" {
  set timezone="UTC"
  skipnextconfig
}

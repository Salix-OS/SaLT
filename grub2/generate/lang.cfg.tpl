# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
source $cfgprefix/include.cfg
initmenu
# next config file to load
function nextconfig {
  loadkeymap
  if [ -n "$timezone" ]; then
    configfile $cfgprefix/boot.cfg
  else
    configfile $cfgprefix/timezone.cfg
  fi
}

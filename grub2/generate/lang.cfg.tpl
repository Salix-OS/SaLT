# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
if [ -z "$included" ]; then
  source $cfgprefix/include.cfg
fi
initmenu
# next config file to load
function nextconfig {
  loadkeymap
  if [ -n "$salt_timezone" ]; then
    configfile $cfgprefix/boot.cfg
  else
    configfile $cfgprefix/timezone.cfg
  fi
}

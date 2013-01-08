# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
if [ -z "$included" ]; then
  source $cfgprefix/include.cfg
fi
initmenu
set default=$salt_kbnum
# next config file to load
function nextconfig {
  loadkeymap
  configfile $cfgprefix/boot.cfg
}


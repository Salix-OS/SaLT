# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
# next config file to load
function nextconfig {
  loadlocale $_lang
  loadkeymap
  if [ -n "$salt_timezone" ]; then
    source $cfgprefix/boot.cfg
  else
    source $cfgprefix/timezone.cfg
  fi
}
newmenu
gettextvar title "Please select your language:"

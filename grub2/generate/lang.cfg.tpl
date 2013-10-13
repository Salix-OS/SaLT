# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
source ${cfgprefix}/include.cfg
# next config file to load
function nextconfig {
  loadlocale $_lang
  loadkeymap
  newmenu $cfgprefix/boot.cfg
}
gettextvar title "Please select your language:"

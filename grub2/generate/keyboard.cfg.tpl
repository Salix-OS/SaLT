# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
# next config file to load
function nextconfig {
  loadkeymap
  source $cfgprefix/boot.cfg
}
newmenu
set timeout=30
set default=$salt_kbnum
gettextvar title "Please select your keyboard layout:"

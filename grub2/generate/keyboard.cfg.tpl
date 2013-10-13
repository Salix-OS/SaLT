# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
source ${cfgprefix}/include.cfg
# next config file to load
function nextconfig {
  loadkeymap
  newmenu $cfgprefix/boot.cfg
}
gettextvar title "Please select your keyboard layout:"
menuentry "Other layout" --class=keyboard {
  gettextvar Lcurrentlayout "Current layout:"
  echo "$Lcurrentlayout $salt_kb"
  gettext "Available layouts:"
  echo $available_layouts
  gettextvar Linputmsg "Enter custom keyboard layout:"
	getInput "$Linputmsg" string ""
  if [ -n "$answer" ]; then
  	set salt_kb="$answer"
  fi
	unset answer
  unset Lcurrentlayout
  unset Linputmsg
  nextconfig
}

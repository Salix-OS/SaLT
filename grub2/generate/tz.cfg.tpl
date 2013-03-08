# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
# next config file to load
function nextconfig {
  configfile $cfgprefix/hwclock.cfg
}
menuclear
unset chosen
unset timeout
unset default
gettextvar title "Please select your time zone city:"

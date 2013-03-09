# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
function nextconfig {
  source $cfgprefix/timezone/$salt_timezone.cfg
}
function skipnextconfig {
  source $cfgprefix/boot.cfg
}
newmenu
gettextvar title "Please select your time zone area:"

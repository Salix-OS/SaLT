# vim: syn=sh et sw=2 st=2 ts=2 tw=0:
# next config file to load
function nextconfig {
  source $cfgprefix/timezone/$salt_timezone.cfg
}
function skipnextconfig {
  source $cfgprefix/boot.cfg
}
menuclear
unset chosen
set timeout=30
set default=0
gettextvar title "Please select your time zone area:"
menuentry "UTC" --class=clock {
  set salt_timezone="UTC"
  set salt_hwclock="UTC"
  skipnextconfig
}

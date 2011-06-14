source ${cfgprefix}/include.cfg
initmenu

# next config file to load
function nextconfig {
  loadkeymap
  configfile ${cfgprefix}/boot.cfg
}

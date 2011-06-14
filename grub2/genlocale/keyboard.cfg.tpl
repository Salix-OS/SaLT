source ${cfgprefix}/include.cfg
initmenu

set default=${kbnum}

# next config file to load
function nextconfig {
  loadkeymap
  configfile ${cfgprefix}/boot.cfg
}


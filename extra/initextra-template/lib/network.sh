#!/bin/sh

SKIPASK=$1
[ -n "$SKIPASK" ] || SKIPASK=false

# load the SaLT library
. /lib/libSaLT

# Remove extra whitespace
crunch() {
  while read line ; do
    echo $line
  done
}

# main loop:
while true; do
  if [ "$SKIPASK" = "false" ]; then
    echo "-- Press [enter] to automatically probe for all network cards"
    echo "-- To skip probing some modules (in case of hangs), enter them after an S:"
    echo "   S eepro100 ne2k-pci"
    echo "-- To probe only certain modules, enter them after a P like this:"
    echo "   P 3c503 3c505 3c507"
    echo "-- To get a list of network modules, enter an L."
    echo "-- To skip the automatic probe entirely, enter a Q now."
    echo
  fi
  # Clear "card found" flag:
  rm -f /tmp/cardfound
  if [ "$SKIPASK" = "false" ]; then
    echocolor $COLOR_BOLD $COLOR_CYAN 'network> '
    read INPUT;
    echo
  else
    INPUT=''
  fi
  if [ "$(echo $INPUT|crunch|cut -d' ' -f1)" = "L" ] \
      || [ "$(echo $INPUT|crunch|cut -d' ' -f1)" = "l" ]; then
    echo 'Available network modules:'
    KVER=$(uname -r)
    for file in /lib/modules/$KVER/kernel/drivers/net/* /lib/modules/$KVER/kernel/arch/i386/kernel/* /lib/modules/$KVER/kernel/drivers/pnp/*; do
      if [ -r $file ]; then
        OUTPUT=$(basename $file .gz)
        OUTPUT=$(basename $OUTPUT .xz)
        OUTPUT=$(basename $OUTPUT .o)
        OUTPUT=$(basename $OUTPUT .ko)
        echo -n "$OUTPUT "
      fi
    done
    echo
    continue
  fi
  if [ ! "$INPUT" = "q" ] && [ ! "$INPUT" = "Q" ] \
      && [ ! "$(echo $INPUT|crunch|cut -d' ' -f1)" = "P" ] \
      && [ ! "$(echo $INPUT|crunch|cut -d' ' -f1)" = "p" ]; then
    echoinfo 'Probing for PCI/EISA network cards:'
    for card in 3c59x acenic de4x5 dgrs eepro100 e1000 e1000e e100 epic100 hp100 ne2k-pci olympic pcnet32 rcpci 8139too 8139cp tulip via-rhine r8169 atl1e sktr yellowfin tg3 dl2k ns83820; do
      SKIP=""
      if [ "$(echo $INPUT|crunch|cut -d' ' -f1)" = "S" ] \
          || [ "$(echo $INPUT|crunch|cut -d' ' -f1)" = "s" ]; then
        for nogood in $(echo $INPUT|crunch|cut -d' ' -f2-) ; do
          if [ "$card" = "$nogood" ]; then
            SKIP="$card"
          fi
        done
      fi
      if [ -z "$SKIP" ]; then
        echon "  * Trying the $card module..."
        modprobe "$card" 2>/dev/null
        grep -q eth0 /proc/net/dev
        if [ $? = 0 ]; then
          echoinfo "SUCCESS: found network card using $card protocol."
          echo "$card" >/tmp/cardfound
          break
        else
          modprobe -r "$card" 2>/dev/null
        fi
      else
        echon "  * Skipping module $card..."
      fi
    done
    if [ ! -r /tmp/cardfound ]; then
      # Don't probe for com20020... it loads on any machine with or without the card.
      echoinfo 'Probing for MCA, ISA, and other PCI network cards:'
      # removed because it needs an irq parameter: arlan
      # tainted, no autoprobe: (arcnet) com90io com90xx
      for card in depca ibmtr 3c501 3c503 3c505 3c507 3c509 3c515 ac3200 acenic at1700 cosa cs89x0 de4x5 de600 de620 e2100 eepro eexpress es3210 eth16i ewrk3 fmv18x forcedeth hostess_sv11 hp-plus hp lne390 ne3210 ni5010 ni52 ni65 sb1000 sealevel smc-ultra sis900 smc-ultra32 smc9194 wd; do 
        SKIP=""
        if [ "$(echo $INPUT|crunch|cut -d' ' -f1)" = "S" ] \
            || [ "$(echo $INPUT|crunch|cut -d' ' -f1)" = "s" ]; then
          for nogood in $(echo $INPUT|crunch|cut -d' ' -f2-) ; do
            if [ "$card" = "$nogood" ]; then
              SKIP="$card"
            fi
          done
        fi
        if [ -z "$SKIP" ]; then
          echon "  * Trying the $card module..."
          modprobe "$card" 2>/dev/null
          grep -q eth0 /proc/net/dev
          if [ $? = 0 ]; then
            echoinfo "SUCCESS: found network card using $card protocol."
            echo "$card" >/tmp/cardfound
            break
          else
            modprobe -r "$card" 2>/dev/null
          fi
        else
          echon "  * Skipping module $card..."
        fi
      done
    fi
    if [ ! -r /tmp/cardfound ]; then
      echo
      echoerror "Sorry, but no network card was detected. Some cards (like non-PCI"
      echoerror "NE2000s) must be supplied with the I/O address to use. If you have"
      echoerror "an NE2000, use this shell and load it with a command like this:"
      echoerror "  modprobe ne io=0x360"
      shell
    fi
  elif [ "$(echo $INPUT|crunch|cut -d' ' -f1)" = "P" ] \
      || [ "$(echo $INPUT|crunch|cut -d' ' -f1)" = "p" ]; then
    echoinfo 'Probing for a custom list of modules:'
    for card in $(echo $INPUT|crunch|cut -d' ' -f2-) ; do
      echon "  * Trying the $card module..."
      modprobe "$card" 2>/dev/null
      grep -q eth0 /proc/net/dev
      if [ $? = 0 ]; then
        echoinfo "SUCCESS: found network card using $card protocol."
        echo "$card" >/tmp/cardfound
        break
      else
        modprobe -r "$card" 2>/dev/null
      fi
    done
  else
    echoinfo 'Skipping automatic module probe.'
  fi
  # end main loop
  break
done

#!/bin/bash
#
# Restart network interfaces
# if ppp0 cellular connection is down

# If this script is sourced from the install script, the variable
# DTUERTPI_DIR will be set and can be used as the base for determining
# folder structure.
# If not set, get the current directory from the bash environment
if [[ -z $DTUERTPI_DIR ]]; then
  SH_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
  SH_SCRIPTS_DIR="$DTUERTPI_DIR"/sh_scripts
fi

# import settings
source "$SH_SCRIPTS_DIR"/script_settings

PING="/usr/bin/ping -q -c1 -W 10 -I ppp0"
HOST="8.8.8.8"

${PING} ${HOST}
if [ $? -ne 0 ]; then
    echo "3G (ppp0) network connection is down! Attempting reconnection."

    /sbin/ifdown --force ppp0
    sleep 10

    if [[ ! -e $MODEMTTYDEV ]]; then
        echo "$MODEMTTYDEV does not exist, trying fix..."
        /usr/bin/lsusb -v &> /dev/null
        sleep 10
    fi

    if [[ -e $MODEMTTYDEV ]]; then
        echo "$MODEMTTYDEV exists!"
        
        PIDs=`lsof -t $MODEMTTYDEV`
        if [[ "" !=  "$PIDs" ]]; then
            echo "killing $PIDs"
            kill $PIDs
            sleep 10
        else
            echo "No processes seem to be using $MODEMTTYDEV"
        fi
    else
        echo "$MODEMTTYDEV does not exist!"
    fi

    /sbin/ifup --force ppp0
    sleep 10
fi

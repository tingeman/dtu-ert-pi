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

source $SH_SCRIPTS_DIR/script_settings
source $WITTYPI_DIR/gpio-util.sh

relay_off() {
    gpio mode 9 out
    gpio mode 11 out

    gpio write 9 0
    gpio write 11 1
}

relay_on() {
    gpio mode 9 out
    gpio mode 11 out

    gpio write 9 1
    gpio write 11 0
}


if [[ "$1" == 'ON' || "$1" == 'on' || "$1" == 'On' ]]; then
    relay_on
elif [[ "$1" == 'OFF' || "$1" == 'off' || "$1" == 'Off' ]]; then
    relay_off
else
    echo 'Unknown command: '"$1"
fi

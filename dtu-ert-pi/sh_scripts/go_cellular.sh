
#!/bin/bash

f_enable_wifi () {
    echo
    echo
    if [[ -z $1  ||  $1 == true ]]; then
        echo '>>> Enabling wifi in /boot/config.txt'
        match=$(grep 'dtoverlay=disable-wifi' /boot/config.txt)
        match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
        if [[ -z "$match" || "$match" == "#"* ]]; then
            echo 'It seems wifi is already enabled.'
        else
            # if disable command is present, comment it
            sed "s/^[[:space:]](dtoverlay=disable-wifi.*)/# \1/"
        fi
    else
        echo '>>> Disabling wifi in /boot/config.txt'
        match=$(grep 'dtoverlay=disable-wifi' /boot/config.txt)
        match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
        if [[ -z "$match" || "$match" == "#"* ]]; then
            # if disable command is not present, or commented, add it
            echo 'dtoverlay=disable-wifi' >> /boot/config.txt
        else
            echo 'It seems wifi is already disabled.'
        fi
    fi
}

# If this script is sourced from the install script, the variable
# DTUERTPI_DIR will be set and can be used as the base for determining
# folder structure.
# If not set, get the current directory from the bash environment
if [[ -z $DTUERTPI_DIR ]]; then
  SH_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
  SH_SCRIPTS_DIR="$DTUERTPI_DIR"/sh_scripts
fi


f_enable_wifi false
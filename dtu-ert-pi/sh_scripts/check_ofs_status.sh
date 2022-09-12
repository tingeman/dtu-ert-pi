#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR"/ofs_utils.sh


printf "\n"
if [[ $(ofs_mounted) -eq 1 ]]; then
    printf "=====================================================================================\n"
    printf "\n"
    printf "OVERLAY FILE SYSTEM IN USE, any changes made will not survive a reboot \n"
    printf "\n"
    printf "=====================================================================================\n"
    printf "\n"
elif [[ $(ofs_enabled) -eq 1 && $(ofs_img_exists) -eq 1 ]]; then
    printf "=====================================================================================\n"
    printf "\n"
    printf "OVERLAY FILE SYSTEM CONFIGURED, any changes made will not survive a reboot \n"
    printf "(unless OFS is disabled before rebooting...) \n"
    printf "\n"
    printf "=====================================================================================\n"
    printf "\n"
fi

if [[ $(ofs_enabled) -eq 1 && $(ofs_img_exists) -eq 1 ]]; then
    printf "NB: overlay file system WILL BE MOUNTED on next reboot!\n"
    printf "\n"
elif [[ $(ofs_enabled) -eq 1 && $(ofs_img_exists) -eq 0 ]]; then
    printf ">>> WARNING: Configuration mismatch, OFS enabled, but image does not exist!\n"
    printf ">>> WARNING: NEXT BOOT WILL LIKELY FAIL!!!\n"
    printf "\n"
fi

if [[ $(ofs_enabled) -eq 1 && $(ofs_img_exists) -eq 1 || $(ofs_mounted) -eq 1 ]]; then
    printf "CHANGES MADE NOW WILL NOT SURVIVE REBOOT!\n"
    printf "\n"
else
    printf "Overlay file system is not in use. Changes made will be persistent...\n"
    printf "\n"
fi


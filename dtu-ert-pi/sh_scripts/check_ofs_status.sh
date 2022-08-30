#!/bin/bash

str=$(mount | grep ' on / ')

OFS_img_exists=false         # does the intrd.img* file exist in filesystem?
OFS_enabled=false            # is overlay file system enabled in /boot/config.txt?
OFS_inuse=false              # is the overlay file system in active use (mounted)?

if ls /boot/intrd.img* 1> /dev/null 2>&1; then
    OFS_img_exists=true
fi

match=$(grep 'initramfs' /boot/config.txt)
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" ]]; then
    # line is missing
    OFS_enabled=false
elif [[  "$match" == "#"* ]]; then
    # line is commented
    OFS_enabled=false
else
    # line exists
    OFS_enabled=true
fi

match=$(mount | grep ' on / ')
if echo "$match" | grep -q 'overlay'; then
    # OFS is mounted
    OFS_inuse=true
elif echo $str | grep -q 'rw'; then
    # OFS is NOT mounted, / is read-write enabled
    OFS_inuse=false
else
    # unkown state (should not happen)
    OFS_inuse=unkonwn_state
fi

printf "\n"
if [[ "$OFS_inuse" == 'true' ]]; then
    printf "=====================================================================================\n"
    printf "\n"
    printf "OVERLAY FILE SYSTEM IN USE, any changes made will not survive a reboot \n"
    printf "\n"
    printf "=====================================================================================\n"
    printf "\n"
elif [[ "$OFS_enabled" == 'true' && "$OFS_img_exists" == 'true' ]]; then
    printf "=====================================================================================\n"
    printf "\n"
    printf "OVERLAY FILE SYSTEM CONFIGURED, any changes made will not survive a reboot \n"
    printf "\n"
    printf "=====================================================================================\n"
    printf "\n"
fi

if [[ "$OFS_enabled" == 'true' && "$OFS_img_exists" == 'true' ]]; then
    printf "Overlay file system image exists and is enabled in /boot/config.txt"
    printf "NB: overlay file system WILL BE MOUNTED on next reboot!\n"
    printf "\n"
elif [[ "$OFS_enabled" == 'true' && "$OFS_img_exists" == 'false' ]]; then
    printf ">>> WARNING: Configuration mismatch, OFS enabled, but image does not exist!"
    printf ">>> WARNING: NEXT BOOT WILL LIKELY FAIL!!!"
    printf "\n"
fi

if [[ "$OFS_enabled" == 'true' && "$OFS_img_exists" == 'true' || "$OFS_inuse" == 'true' ]]; then
    printf "CHANGES MADE NOW WILL NOT SURVIVE REBOOT!"
    printf "\n"
else
    printf "Overlay file system is not in use."
    printf "Any changes made will be persistent..."
    printf "\n"
fi





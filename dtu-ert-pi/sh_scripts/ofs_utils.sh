
ofs_img_exists() {
    # Returns 1 if OFS boot image exists
    #         0 if it doesnt
    if ls /boot/initrd.img* 1> /dev/null 2>&1; then
        echo -n '1'
    else
        echo -n '0'
    fi
}


ofs_enabled() {
    # Returns 1 if OFS is enabled in /boot/config.txt
    #         0 if it isn't
    match=$(grep 'initramfs' /boot/config.txt)
    match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
    if [[ -z "$match" ]]; then
        # line is missing
        echo -n '0'
    elif [[  "$match" == "#"* ]]; then
        # line is commented
        echo -n '0'
    else
        # line exists
        echo -n '1'
    fi
}


ofs_mounted() {
    # Returns 1 if OFS is mounted
    #         0 if it isn't
    #        -1 if state is not recongnized
    match=$(mount | grep ' on / ')
    if echo "$match" | grep -q 'overlay'; then
        # OFS is mounted
        echo -n '1'
    elif echo $match | grep -q 'rw'; then
        # OFS is NOT mounted, / is read-write enabled
        echo -n '0'
    else
        # unkown state (should not happen)
        echo -n '-1'
    fi
}

fs_changes_persistent() {
    # Returns 1 if fs changes will be retained at next reboot
    #         0 if they will not
    #         2 if disabling OFS before reboot can make changes persistent
    
    if [[ $(ofs_mounted) -eq 1 ]]; then
        echo -n '0'
    elif [[ $(ofs_enabled) -eq 1 && $(ofs_mounted) -eq 0 ]]; then
       echo -n '2'
    else
       echo -n '1'
    fi
}


get_overlay_now() {
  grep -q "boot=overlay" /proc/cmdline
  echo $?
}


get_bootro_now() {
  findmnt /boot | grep -q " ro,"
  echo $?
}

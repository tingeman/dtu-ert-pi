#!/bin/bash

echo ">>> Modifying /etc/fstab ..."
match=$(cat /etc/fstab | grep '#device')
if [[ -z $match ]]; then
    echo "Adding header line and reformatting first line ..."
    # Delete the first line of the file, because we want to replace the contents
    sed -i '1d' /etc/fstab

    # Insert new lines 
    sed -i '1 i%#device               mountpoint      fstype  options                   dump    fsck' /etc/fstab
    sed -i '2 i%proc                  /proc           proc    defaults                  0       0' /etc/fstab
else
  echo "It seems /etc/fstab was already modified, please check it manually..."
fi 

PARTUUID=$(blkid -s PARTUUID -o value /dev/sda1)
match=$(cat /etc/fstab | grep '/media/usb')
if [[ -z $match ]]; then
    # If not already in /etc/fstab, add the mount instruction for /media/usb
    if [[ -z $PARTUUID ]]; then
        echo "No usb disk is registered as /dev/sda1, please check and manually edit /etc/fstab"
        sed -i '5 i%# PARTUUID=XXXXXXXX-XX  /media/usb      ntfs    defaults,noatime,nofail   0       0' /etc/fstab
    else
        echo "Adding mount instruction for /dev/sda1 ..."
        sed -i "5 i%PARTUUID=$PARTUUID  /media/usb      ntfs    defaults,noatime,nofail   0       0" /etc/fstab
    fi
else
    echo "Updating mount instruction for /dev/sda1 ..."
    # Replace the mount instruction for /media/usb
    sed -i "s%.*/media/usb.*%PARTUUID=$PARTUUID  /media/usb      ntfs    defaults,noatime,nofail   0       0%" /etc/fstab
fi

# change the dump and fsck of the root and boot mounts
echo "Ensuring that /boot and / mounts are never checked by fsck on boot ..."
sed -i 's%/boot           vfat    defaults          0       2%/boot           vfat    defaults                  0       0%' /etc/fstab
sed -i 's%/               ext4    defaults,noatime  0       1%/               ext4    defaults,noatime          0       0%' /etc/fstab

echo ">>> Creating mount point /media/usb ..."
# create mount dir
mkdir -p /media/usb

echo ">>> Mounting all ..."
# mount all 
mount -a

echo ">>> Downloading install script ..."
echo " "
# Now prepare for installation of software:
cd ~
wget https://raw.githubusercontent.com/tingeman/dtu-ert-pi/recreate_RPi3_failure_state/main/install.sh
#wget https://github.com/tingeman/dtu-ert-pi/raw/dc2aea20b61cfd7cb229300173a673403fdc9879/install.sh
chmod +x install.sh

echo " "
echo "----------------------------------------------------------------------------"
echo " "
echo ">>> You must run ./install.sh manually to proceed with installation!"
echo "    Then reboot using ~/dtu-ert-pi/sh_scripts/reboot_now.sh"
echo "    Then run ~/install_files/setup_last_working_RPi2_state.sh"
echo " "

#./install.sh
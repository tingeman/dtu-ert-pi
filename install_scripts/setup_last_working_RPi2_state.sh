#!/bin/bash

echo ">>> Final preparations for to resemble RPi2 state before attempted update..."

echo "Reconfiguring wittypi ..."
#~/install_files/update_wittypi_codebase.sh
~/install_files/reconfigure_wittypi.sh

echo "Reinstalling autossh ..."
~/install_files/reinstall_autossh.sh

echo "Reinstalling dhcp server ..."
~/install_files/reinstall_dhcp_server.sh

echo "Installing crontab ..."
~/dtu-ert-pi/sh_scripts/auto_configure_crontab.sh

echo "Changing MTU setting for ppp0 ..."
ifconfig ppp0 mtu 1200

echo " "
echo "--------------------------------------------------------------------------------------------"
echo " "
echo ">>> The system should now be in the same state as RPi2 before the fatal update attempt!"
echo "    Use raspi-config to enable overlay file system"
echo "    Then reboot and proceed according to failed update procedure to recreate failure."
echo " "

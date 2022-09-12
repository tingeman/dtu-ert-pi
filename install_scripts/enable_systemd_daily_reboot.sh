#!/bin/bash

[ -z $BASH ] && { exec bash "$0" "$@" || exit; }

# error counter
ERR=0

# check if sudo is used
if [ "$(id -u)" != 0 ]; then
  echo
  echo 'Sorry, you need to run this script with sudo'
  exit 1
fi

# If this script is sourced from the install script, the variable
# DTUERTPI_DIR will be set and can be used as the base for determining
# folder structure.
# If not set, get the current directory from the bash environment
if [[ -z $DTUERTPI_DIR ]]; then
  SH_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
  SH_SCRIPTS_DIR="$DTUERTPI_DIR"/sh_scripts
fi


echo " "
echo ">>> Installing forced_reboot timer to reboot at 04:00 UTC every day"

echo "Copying systemd files from templates..."
cp -f $SH_SCRIPTS_DIR/template_files/forced_reboot.* /etc/systemd/system/

echo "Reloading daemons..."
systemctl daemon-reload

echo "Enabling timer..."
systemctl enable --now forced_reboot.timer

# don't enable the forced_reboot.service. That would result in the reboot running immediately at boot (infinite loop)

# reconfigure crontab
$SH_SCRIPTS_DIR/auto_configure_crontab.sh crontab_template_noreboot.txt

echo "done"
[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#!/bin/bash
# file: install.sh
#
# This script will install required software for Witty Pi.
# It is recommended to run it in your home directory.
#

# target directories
INSTALL_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$INSTALL_SCRIPTS_DIR/.."
TMP_DIR="$INSTALL_SCRIPTS_DIR/tmp"
WITTYPI_DIR="$BASE_DIR/wittypi"
DTUERTPI_DIR="$BASE_DIR/dtu-ert-pi"

# PREDEFINED SETTINGS:

# [GENERAL] -----------------------------------------------
USB_MOUNT_POINT=/media/usb
HOSTNAME=$(hostname)

# [UPLOAD SERVER] -----------------------------------------
SERVER_IP="192.38.64.71"
PORT="22"

# [AUTOSSH] -----------------------------------------
SSHKEY=/root/.ssh/"$HOSTNAME"_sshkey
SSHUSER=$HOSTNAME
FWD_PORT="2221"



echo '================================================================================'
echo '|                                                                              |'
echo '|                   DTU-ERT-Pi reconfigure paths etc.                          |'
echo '|                                                                              |'
echo '================================================================================'
# Strongly inspired by WittyPi install script :-)


# ==============================================================================
# Initial checks
# ==============================================================================

# error counter
ERR=0

# check if sudo is used
if [ "$(id -u)" != 0 ]; then
  echo
  echo '>>> Sorry, you need to run this script with sudo'
  ((ERR++))
fi

if grep -qs "$USB_MOUNT_POINT " /proc/mounts; then
    echo ">>> USB drive is mounted... good!"
else
    echo ">>> USB drive is not mounted. Please mount at $USB_MOUNT_POINT and rerun this script"
    ((ERR++))
fi

if [[ check_python_function == true ]]; then
    f_check_python_version
fi

if [[ $ERR -ne 0 ]]; then
  echo '>>> Fix issues, and rerun script ...'
  exit 1
fi


# include all the functions handling installations
. $INSTALL_SCRIPTS_DIR/install_functions.sh


# ==============================================================================
# Configure settings files
# ==============================================================================


echo ">>> Creating folders for RW access on usb drive..."
if [[ ! -d $USB_MOUNT_POINT/logs ]]; then
  mkdir -p $USB_MOUNT_POINT/logs
fi
if [[ ! -d $USB_MOUNT_POINT/crontabs ]]; then
  mkdir -p $USB_MOUNT_POINT/crontabs
fi
if [[ ! -d $USB_MOUNT_POINT/from_terrameter ]]; then
  mkdir -p $USB_MOUNT_POINT/from_terrameter
fi
#if [[ ! -d $USB_MOUNT_POINT/var/lib/ntp ]]; then
#  mkdir -p $USB_MOUNT_POINT/var/lib/ntp
#fi
#if [[ ! -d $USB_MOUNT_POINT/var/tmp ]]; then
#  mkdir -p $USB_MOUNT_POINT/var/tmp
#fi

echo ">>> Copying and modifying config_python.yml file..."
# Modify settings in config_python.yml
cp -f $INSTALL_SCRIPTS_DIR/template_files/python_config_rpi4.yml $DTUERTPI_DIR/python_config.yml

# search and replace placeholder text
sed -i "{s#\$USB_MOUNT_POINT#$USB_MOUNT_POINT#}" $DTUERTPI_DIR/python_config.yml


echo ">>> Copying and modifying script_settings file..."
# Modify settings in script_settings.conf
cp -f $INSTALL_SCRIPTS_DIR/template_files/script_settings_rpi4 $DTUERTPI_DIR/sh_scripts/script_settings

# search and replace placeholder text
sed -i "{s#^[[:space:]]*DTUERTPI_DIR=.*#DTUERTPI_DIR=\"$DTUERTPI_DIR\"#}" $DTUERTPI_DIR/sh_scripts/script_settings
sed -i "{s#^[[:space:]]*WITTYPI_DIR=.*#WITTYPI_DIR=\"$WITTYPI_DIR\"#}" $DTUERTPI_DIR/sh_scripts/script_settings
sed -i "{s#^[[:space:]]*USB_MOUNT_POINT=.*#USB_MOUNT_POINT=\"$USB_MOUNT_POINT\"#}" $DTUERTPI_DIR/sh_scripts/script_settings
sed -i "{s#^[[:space:]]*SERVER_IP=.*#SERVER_IP=\"$SERVER_IP\"#}" $DTUERTPI_DIR/sh_scripts/script_settings
sed -i "{s#^[[:space:]]*PORT=.*#PORT=\"$PORT\"#}" $DTUERTPI_DIR/sh_scripts/script_settings


echo ">>> The configuration files were replaced! (python_config.yml and script_settings)."
echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
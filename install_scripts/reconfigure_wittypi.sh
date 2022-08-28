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

# [WITTYPI] -----------------------------------------------
WITTYPI_USE_GLOBAL_SETTINGS=true  # Use these settings instead of those locally defined in wittypi install script

WITTYPI_DEFAULT_POWER_STATE=1      # 1 = TURN ON; 0 = STAY OFF, when power is connected
WITTYPI_LOW_VOLTAGE_THRESHOLD=65   # threshold voltage * 10 (as integer)
WITTYPI_RECOVERY_VOLTAGE_THRESHOLD=100   # threshold voltage * 10 (as integer)


echo '================================================================================'
echo '|                                                                              |'
echo '|                   DTU-ERT-Pi reinstall autossh                               |'
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
  echo 'Sorry, you need to run this script with sudo'
  exit 1
fi


# include all the functions handling installations
. $INSTALL_SCRIPTS_DIR/install_functions.sh



# ==============================================================================
# Configure Witty Pi settings
# ==============================================================================

f_configure_wittypi  || (ERR++)


echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
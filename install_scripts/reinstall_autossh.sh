[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#!/bin/bash
# file: install.sh
#
# This script will install required software for Witty Pi.
# It is recommended to run it in your home directory.
#

# target directories
INSTALL_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(cd "$INSTALL_SCRIPTS_DIR/.." && pwd)
TMP_DIR="$INSTALL_SCRIPTS_DIR/tmp"
WITTYPI_DIR="$BASE_DIR/wittypi"
DTUERTPI_DIR="$BASE_DIR/dtu-ert-pi"

# PREDEFINED SETTINGS:

# [GENERAL] -----------------------------------------------
HOSTNAME=$(hostname)

# [UPLOAD SERVER] -----------------------------------------
SERVER_IP="192.38.64.71"
PORT="22"

# [AUTOSSH] -----------------------------------------
SSHKEY=/root/.ssh/"$HOSTNAME"_sshkey
SSHUSER=$HOSTNAME

if [[ $HOSTNAME == QEQ-ERT-02-RPi1 ]]; then
  FWD_PORT="3331"
elif [[ $HOSTNAME == QEQ-ERT-02-RPi2 ]]; then
  FWD_PORT="3332"
elif [[ $HOSTNAME == QEQ-ERT-02-RPi2 ]]; then
  FWD_PORT="3333"  
elif [[ $HOSTNAME == QEQ-ERT-02-RPi2 ]]; then
  FWD_PORT="3334"  
else
  FWD_PORT="2221"
fi

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
# Installing and configuring autossh
# ==============================================================================

f_configure_autossh 


echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
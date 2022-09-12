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


echo '================================================================================'
echo '|                                                                              |'
echo '|                   DTU-ERT-Pi dhcp server service                             |'
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
# Remove current install if present
# ==============================================================================

apt remove isc-dhcp-server

if [[ -f '/etc/default/isc-dhcp-server' ]]; then
  rm '/etc/default/isc-dhcp-server'
fi

if [[ -d '/etc/dhcp' ]]; then
  rm -r '/etc/dhcp'
fi

if [[ -f '/etc/systemd/system/isc-dhcp-server.service' ]]; then
  rm '/etc/systemd/system/isc-dhcp-server.service'
fi


# ==============================================================================
# Installing and configuring dhcp server service
# ==============================================================================

f_configure_dhcp_server


echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
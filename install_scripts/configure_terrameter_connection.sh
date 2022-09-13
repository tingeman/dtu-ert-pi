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
# Create terrameter connection
# ==============================================================================

if [[ $create_terrameter_connection == true ]]; then
    f_configure_terrameter_connection
fi


echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
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

# Two crontab template files are available. The first for production use.
# The second for stress testing the booting and shutdown of the Raspberry Pi.
#CRONTAB_TEMPLATE=$DTUERTPI_DIR/sh_scripts/template_files/crontab_template.txt
CRONTAB_TEMPLATE=$DTUERTPI_DIR/sh_scripts/template_files/crontab_template_shutdown.txt

# [GIT BRANCH] --------------------------------------------
GIT_BRANCH=develop      # master or develop



echo '================================================================================'
echo '|                                                                              |'
echo '|                   DTU-ERT-Pi update py and sh files                          |'
echo '|                                                                              |'
echo '================================================================================'
# Strongly inspired by WittyPi install script :-)


# ==============================================================================
# Initial checks
# ==============================================================================

# check if sudo is used
if [ "$(id -u)" != 0 ]; then
  echo
  echo 'Sorry, you need to run this script with sudo'
  exit 1
fi

if [[ check_python_function == true ]]; then
    f_check_python_version
fi


# ==============================================================================
# Install DTU-ERT-Pi
# ==============================================================================

# This install script is downloadable here:

# master branch version:
# wget ????

# develop/main branch version:
# wget https://github.com/tingeman/dtu-ert-pi/raw/develop/main/install.sh


# error counter
ERR=0

mkdir -p "$TMP_DIR"
chown -R $USER:$(id -g -n $USER) "$TMP_DIR" || ((ERR++))

echo 
echo
echo '>>> Downloading dtu-ert-pi code...'
if [[ -d "$DTUERTPI_DIR" ]]; then
  echo 'Seems dtu-ert-pi is installed already, skip this step.'
else
  if [[ -f "$TMP_DIR/dtu-ert-pi.zip" ]]; then 
    rm -y "$TMP_DIR/dtu-ert-pi.zip"
  fi
  if [[ $GIT_BRANCH == develop ]]; then
    wget https://github.com/tingeman/dtu-ert-pi/archive/refs/heads/develop/main.zip -O "$TMP_DIR/dtu-ert-pi.zip"
    SRC_DIR="$TMP_DIR"/dtu-ert-pi-develop-main
  elif [[ $GIT_BRANCH == master ]]; then
    wget https://github.com/tingeman/dtu-ert-pi/archive/refs/heads/master.zip -O "$TMP_DIR/dtu-ert-pi.zip"
    SRC_DIR="$TMP_DIR"/dtu-ert-pi-master
  else
    echo 'Unknown git branch specified, aborting!'
    exit 1
  fi
  if [[ -d $SRC_DIR ]]; then
    rm -r $SRC_DIR
  fi
  unzip -q "$TMP_DIR"/dtu-ert-pi.zip -d "$TMP_DIR"/ 
  cp -rf "$SRC_DIR"/install_scripts/* "$INSTALL_SCRIPTS_DIR"     # OK
  cp -rf "$SRC_DIR"/install.sh "$BASE_DIR"/install.sh        # OK
  rsync -avm --include='*.py' --include='*.sh' -f 'hide,! */' "$SRC_DIR"/DTU_ERT_Pi "$DTUERTPI_DIR"
  chown -R $USER:$(id -g -n $USER) "$DTUERTPI_DIR" || ((ERR++))
  chown -R $USER:$(id -g -n $USER) "$INSTALL_SCRIPTS_DIR" || ((ERR++))
  chown $USER:$(id -g -n $USER) "$BASE_DIR"/install.sh || ((ERR++))
  chmod -R +x "$INSTALL_SCRIPTS_DIR"/*.sh
  chmod -R +x "$DTUERTPI_DIR"/*.sh
  chmod -R +x "$BASE_DIR"/install.sh
  sleep 2
fi

echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
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
USB_MOUNT_POINT=/media/usb
HOSTNAME=$(hostname)


# [WITTYPI] -----------------------------------------------
WITTYPI_GIT_BRANCH=develop      # main or develop
WITTYPI_DOWNLOAD_URL="https://github.com/tingeman/Witty-Pi-4/archive/refs/heads"
# WITTYPI_DOWNLOAD_URL="https://www.uugear.com/repo/WittyPi4/LATEST"    # Uncomment to install UUGEAR latest version instead

WITTYPI_DEFAULT_POWER_STATE=1      # 1 = TURN ON; 0 = STAY OFF, when power is connected
WITTYPI_LOW_VOLTAGE_THRESHOLD=55   # threshold voltage * 10 (as integer)
WITTYPI_RECOVERY_VOLTAGE_THRESHOLD=100   # threshold voltage * 10 (as integer)


echo '================================================================================'
echo '|                                                                              |'
echo '|                   DTU-ERT-Pi update Witty Pi scripts                         |'
echo '|                                                                              |'
echo '================================================================================'
# Strongly inspired by WittyPi install script :-)

source $WITTYPI_DIR/utilities.sh

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

#  wget $WITTYPI_INSTALL_SCRIPT_URL -O "$INSTALL_SCRIPTS_DIR"/wittypi_install.sh
#  chmod +x "$INSTALL_SCRIPTS_DIR"/wittypi_install.sh
#  source "$INSTALL_SCRIPTS_DIR"/wittypi_install.sh

# error counter
ERR=0

if [[ ! -d $TMP_DIR ]]; then
  mkdir -p "$TMP_DIR"
  chown -R $USER:$(id -g -n $USER) "$TMP_DIR" || ((ERR++))
fi

echo 
echo
echo '>>> Downloading wittypi code...'

if [[ -f "$TMP_DIR/wittyPi.zip" ]]; then 
  rm "$TMP_DIR/wittyPi.zip"
fi
if [[ $WITTYPI_GIT_BRANCH == develop ]]; then
  wget "$WITTYPI_DOWNLOAD_URL"/develop.zip -O "$TMP_DIR/wittyPi.zip"
  SRC_DIR="$TMP_DIR"/Witty-Pi-4-develop
elif [[ $WITTYPI_GIT_BRANCH == master ]]; then
  wget "$WITTYPI_DOWNLOAD_URL"/main.zip -O "$TMP_DIR/wittyPi.zip"
  SRC_DIR="$TMP_DIR"/Witty-Pi-4-main
else
  echo 'Unknown git branch specified, aborting!'
  exit 1
fi
if [[ -d $SRC_DIR ]]; then
  rm -r $SRC_DIR
fi
unzip -q "$TMP_DIR"/wittyPi.zip -d "$TMP_DIR"/ 
cp -rf "$SRC_DIR"/Software/wittypi/*.sh "$WITTYPI_DIR"   

input=""
while [ "$input" != yes ] && [ "$input" != no ]
do
  read -rp 'Overwrite main wittypi install.sh script? [yes/no]: '  input
done

if [[ $input == yes ]]; then
  cp -rf "$SRC_DIR"/Software/install.sh "$INSTALL_SCRIPTS_DIR"/wittypi_install.sh   
  chmod -R +x "$INSTALL_SCRIPTS_DIR"/wittypi_install.sh
  echo "The main install.sh was REPLACED."
else
  echo "The main install.sh was not updated."
fi

echo

chown -R $USER:$(id -g -n $USER) "$WITTYPI_DIR" || ((ERR++))
chown -R $USER:$(id -g -n $USER) "$INSTALL_SCRIPTS_DIR" || ((ERR++))
chmod -R +x "$INSTALL_SCRIPTS_DIR"/*.sh
chmod -R +x "$WITTYPI_DIR"/*.sh
sleep 2


echo
if [ $ERR -eq 0 ]; then
  echo "All Witty Pi .sh scripts updated to latest version from $WITTYPI_DOWNLOAD_URL/$WITTYPI_GIT_BRANCH"
  echo "wittyPi.conf and all *.wpi files were not touched."
  echo '>>> All done :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
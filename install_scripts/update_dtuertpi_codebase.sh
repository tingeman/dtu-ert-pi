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

# Two crontab template files are available. The first for production use.
# The second for stress testing the booting and shutdown of the Raspberry Pi.
#CRONTAB_TEMPLATE=$DTUERTPI_DIR/sh_scripts/template_files/crontab_template.txt
CRONTAB_TEMPLATE=$DTUERTPI_DIR/sh_scripts/template_files/crontab_template_shutdown.txt

# [GIT BRANCH] --------------------------------------------
GIT_BRANCH=live_test      # master, develop or live_test



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

if [[ -f "$TMP_DIR/dtu-ert-pi.zip" ]]; then 
  rm "$TMP_DIR/dtu-ert-pi.zip"
fi
if [[ $GIT_BRANCH == develop ]]; then
  wget https://github.com/tingeman/dtu-ert-pi/archive/refs/heads/develop/main.zip -O "$TMP_DIR/dtu-ert-pi.zip"
  SRC_DIR="$TMP_DIR"/dtu-ert-pi-develop-main
elif [[ $GIT_BRANCH == master ]]; then
  wget https://github.com/tingeman/dtu-ert-pi/archive/refs/heads/master.zip -O "$TMP_DIR/dtu-ert-pi.zip"
  SRC_DIR="$TMP_DIR"/dtu-ert-pi-master
elif [[ $GIT_BRANCH == live_test ]]; then
  wget https://github.com/tingeman/dtu-ert-pi/archive/refs/heads/live_test.zip -O "$TMP_DIR/dtu-ert-pi.zip"
  SRC_DIR="$TMP_DIR"/dtu-ert-pi-live_test
else
  echo 'Unknown git branch specified, aborting!'
  exit 1
fi
if [[ -d $SRC_DIR ]]; then
  rm -r $SRC_DIR
fi
unzip -q "$TMP_DIR"/dtu-ert-pi.zip -d "$TMP_DIR"/ 
cp -rf "$SRC_DIR"/install_scripts/* "$INSTALL_SCRIPTS_DIR"   

input=""
while [ "$input" != yes ] && [ "$input" != no ]
do
  read -rp 'Overwrite main install.sh script? [yes/no]: '  input
done

if [[ $input == yes ]]; then
  cp -rf "$SRC_DIR"/install.sh "$BASE_DIR"/install.sh        
  chmod -R +x "$BASE_DIR"/install.sh
  echo "The main install.sh was REPLACED."
else
  echo "The main install.sh was not updated."
fi

echo

rsync -avm --include='*.py' --include='*.sh' -f 'hide,! */' "$SRC_DIR"/dtu-ert-pi/ "$DTUERTPI_DIR"/
cp -rf "$SRC_DIR"/dtu-ert-pi/sh_scripts/template_files/* "$DTUERTPI_DIR"/sh_scripts/template_files/

chown -R $USER:$(id -g -n $USER) "$DTUERTPI_DIR" || ((ERR++))
chown -R $USER:$(id -g -n $USER) "$INSTALL_SCRIPTS_DIR" || ((ERR++))
chown $USER:$(id -g -n $USER) "$BASE_DIR"/install.sh || ((ERR++))
chmod -R +x "$INSTALL_SCRIPTS_DIR"/*.sh
chmod -R +x "$DTUERTPI_DIR"/sh_scripts/*.sh
sleep 2


echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#!/bin/bash
# file: install.sh
#
# This script will install required software for Witty Pi.
# It is recommended to run it in your home directory.
#

# target directories
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_SCRIPTS_DIR="$BASE_DIR/install_files"
TMP_DIR="$INSTALL_SCRIPTS_DIR/tmp"
WITTYPI_DIR="$BASE_DIR/wittypi"
DTUERTPI_DIR="$BASE_DIR/dtu-ert-pi"

# RUN FLAGS
enable_bluetooth=false
enable_wifi=true
check_python_function=true
install_python_dependencies=true
install_git=true
configure_time_settings=true
configure_dhcp_client=true
configure_dhcp_server=true
configure_modem_connection=true
configure_autossh=true
enable_I2C=true
install_wittypi=true
configure_wittypi=true 

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

# [UPLOAD SERVER] -----------------------------------------
SERVER_IP="192.38.64.71"
PORT="22"

# [AUTOSSH] -----------------------------------------
SSHKEY=/root/.ssh/"$HOSTNAME"_sshkey
SSHUSER=$HOSTNAME
FWD_PORT="2221"

# [WITTYPI] -----------------------------------------------
WITTYPI_USE_GLOBAL_SETTINGS=true  # Use these settings instead of those locally defined in wittypi install script
WITTYPI_INSTALL_SCRIPT_URL="https://github.com/tingeman/Witty-Pi-4/raw/develop/Software/install.sh"
WITTYPI_DOWNLOAD_URL="https://github.com/tingeman/Witty-Pi-4/archive/refs/heads/main.zip"
# WITTYPI_DOWNLOAD_URL="https://www.uugear.com/repo/WittyPi4/LATEST"    # Uncomment to install UUGEAR latest version instead
INSTALL_UWI=false     # Set following line to 'true' to install UUGEAR Web Interface
UWI_DOWNLOAD_URL="https://www.uugear.com/repo/UWI/installUWI.sh"

WITTYPI_DEFAULT_POWER_STATE=1      # 1 = TURN ON; 0 = STAY OFF, when power is connected
WITTYPI_LOW_VOLTAGE_THRESHOLD=55   # threshold voltage * 10 (as integer)
WITTYPI_RECOVERY_VOLTAGE_THRESHOLD=100   # threshold voltage * 10 (as integer)




echo '================================================================================'
echo '|                                                                              |'
echo '|                   DTU-ERT-Pi Software Installation Script                    |'
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


# ==============================================================================
# Install DTU-ERT-Pi
# ==============================================================================

# This install script is downloadable here:

# master branch version:
# wget ????

# develop/main branch version:
# wget https://github.com/tingeman/dtu-ert-pi/raw/develop/main/install.sh


mkdir -p "$TMP_DIR"
chown -R $USER:$(id -g -n $USER) "$TMP_DIR" || ((ERR++))

echo 
echo
echo '>>> Downloading dtu-ert-pi code...'
if [ -d "$DTUERTPI_DIR" ]; then
  echo 'Seems dtu-ert-pi is installed already, skip this step.'
else
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
  unzip -q "$TMP_DIR"/dtu-ert-pi.zip -d "$TMP_DIR"/ 
  cp -rf "$SRC_DIR"/install_scripts/* "$INSTALL_SCRIPTS_DIR"
  cp -rf "$SRC_DIR"/dtu-ert-pi "$DTUERTPI_DIR"
  #rm -r "$SRC_DIR" "$TMP_DIR"/dtu-ert-pi.zip
  chown -R $USER:$(id -g -n $USER) "$DTUERTPI_DIR" || ((ERR++))
  chown -R $USER:$(id -g -n $USER) "$INSTALL_SCRIPTS_DIR" || ((ERR++))
  chmod -R +x "$INSTALL_SCRIPTS_DIR"/*.sh
  chmod -R +x "$DTUERTPI_DIR"/sh_scripts/*.sh
  sleep 2
fi


# include all the functions handling installations
. $INSTALL_SCRIPTS_DIR/install_functions.sh


# ==============================================================================
# Disabling bluetooth, enabling wifi
# ==============================================================================

f_configure_fan_control


# ==============================================================================
# Disabling bluetooth, enabling wifi
# ==============================================================================

f_enable_bluetooth $enable_bluetooth
f_enable_wifi $enable_wifi


# ==============================================================================
# Configuring time related settings
# ==============================================================================

if [[ $configure_time_settings == true ]]; then
    f_configure_time_settings
fi

# ==============================================================================
# Setting up dhcp client settings
# ==============================================================================

if [[ $configure_dhcp_client == true ]]; then
    f_configure_dhcp_client
fi

# ==============================================================================
# Installing and configuring dhcp server
# ==============================================================================

if [[ $configure_dhcp_server == true ]]; then
    f_configure_dhcp_client
fi

# ==============================================================================
# Installing and configuring modem connection
# ==============================================================================

if [[ $configure_modem_connection == true ]]; then
    f_configure_modem_connection
fi

# ==============================================================================
# Installing and configuring autossh
# ==============================================================================

if [[ $configure_autossh == true ]]; then
    f_configure_autossh 
fi


# ==============================================================================
# Installing and configuring python dependencies
# ==============================================================================

if [[ $install_python_dependencies == true ]]; then
    echo
    echo
    echo ">>> Installing additional python dependencies using apt-get..."
    apt-get install -y python3-dev build-essential libffi-dev || ((ERR++))
    apt-get install -y python3-pip || ((ERR++))

    echo
    echo
    echo ">>> Installing required python packages..."
    python3 -m pip install requests netifaces smbus2 paramiko pyyaml numpy vcgencmd

    echo
    echo
    echo ">>> Installing nice-to-have python packages..."
    python3 -m pip install ipython pyserial ipdb
fi

if [[ -z install_git || $install_git == true ]]; then
    echo
    echo
    echo ">>> Installing git, bc etc..."
    apt-get install -y git bc || ((ERR++))
else
    echo ">>> Skipping installation of git"
fi

# ==============================================================================
# Installing and enabling I2C
# ==============================================================================

if [[ $enable_I2C == true ]]; then
    f_enable_I2C
fi


# ==============================================================================
# Setting the locale
# ==============================================================================

# make sure da_DK.UTF-8 locale is installed
echo
echo
echo '>>> Make sure da_DK.UTF-8 locale is installed'
locale_commentout=$(sed -n 's/\(#\).*da_DK.UTF-8 UTF-8/1/p' /etc/locale.gen)
if [[ $locale_commentout -ne 1 ]]; then
  echo 'Seems da_DK.UTF-8 locale has been installed, skip this step.'
else
  sed -i.bak 's/^.*\(da_DK.UTF-8[[:blank:]]\+UTF-8\)/\1/' /etc/locale.gen
  locale-gen
fi

systemctl enable console-setup
systemctl restart console-setup


# ==============================================================================
# Install WittyPi
# ==============================================================================


if [[ $install_wittypi == true ]]; then
  echo
  echo
  echo '>>> Installing Witty Pi 4 software...'
  echo
  wget $WITTYPI_INSTALL_SCRIPT_URL -O "$INSTALL_SCRIPTS_DIR"/wittypi_install.sh
  chmod +x "$INSTALL_SCRIPTS_DIR"/wittypi_install.sh
  source "$INSTALL_SCRIPTS_DIR"/wittypi_install.sh
else
  echo ">>> Skipping installation of Witty Pi 4 software"
fi


# wget https://github.com/tingeman/Witty-Pi-4/archive/refs/heads/main.zip -O "$TMP_DIR/wittyPi.zip"
# unzip "$TMP_DIR/wittyPi.zip" -d "$TMP_DIR/" 

# wget https://github.com/silent001/Witty-Pi-4/archive/master.zip -O "${HOME}/Downloads/wittyPi.zip"
# unzip "${HOME}/Downloads/wittyPi.zip" -d "${HOME}/Downloads/" \
# && cp -rf "${HOME}/Downloads/Witty-Pi-4-main/Software/wittypi" "${HOME}/Downloads/Witty-Pi-4-main/Software/install.sh" "${HOME}" \
# && rm -r "${HOME}/Downloads/Witty-Pi-4-main" "${HOME}/Downloads/wittyPi.zip"
# cd wittypi
# chmod +x wittyPi.sh
# chmod +x daemon.sh
# chmod +x syncTime.sh
# chmod +x runScript.sh
# chmod +x beforeScript.sh
# chmod +x afterStartup.sh


#wget https://github.com/tingeman/Witty-Pi-4/archive/refs/heads/main.zip -O "$TMP_DIR/wittyPi.zip"
#unzip "$TMP_DIR/wittyPi.zip" -d "$TMP_DIR/" 

# wget https://github.com/silent001/Witty-Pi-4/archive/master.zip -O "${HOME}/Downloads/wittyPi.zip"
# unzip "${HOME}/Downloads/wittyPi.zip" -d "${HOME}/Downloads/" \
# && cp -rf "${HOME}/Downloads/Witty-Pi-4-main/Software/wittypi" "${HOME}/Downloads/Witty-Pi-4-main/Software/install.sh" "${HOME}" \
# && rm -r "${HOME}/Downloads/Witty-Pi-4-main" "${HOME}/Downloads/wittyPi.zip"
# cd wittypi
# chmod +x wittyPi.sh
# chmod +x daemon.sh
# chmod +x syncTime.sh
# chmod +x runScript.sh
# chmod +x beforeScript.sh
# chmod +x afterStartup.sh

# # install wittyPi
# if [ $ERR -eq 0 ]; then
#   echo '>>> Install wittypi'
#   if [ -d "wittypi" ]; then
#     echo 'Seems wittypi is installed already, skip this step.'
#   else
#     wget https://www.uugear.com/repo/WittyPi4/LATEST -O wittyPi.zip || ((ERR++))
#     unzip wittyPi.zip -d wittypi || ((ERR++))
#     cd wittypi
#     chmod +x wittyPi.sh
#     chmod +x daemon.sh
#     chmod +x runScript.sh
#     chmod +x beforeScript.sh
#     chmod +x afterStartup.sh
#     chmod +x beforeShutdown.sh
#     sed -e "s#/home/pi/wittypi#$DIR#g" init.sh >/etc/init.d/wittypi
#     chmod +x /etc/init.d/wittypi
#     update-rc.d wittypi defaults || ((ERR++))
#     touch wittyPi.log
#     touch schedule.log
#     cd ..
#     chown -R $SUDO_USER:$(id -g -n $SUDO_USER) wittypi || ((ERR++))
#     sleep 2
#     rm wittyPi.zip
#   fi
# fi

# # install UUGear Web Interface
# curl https://www.uugear.com/repo/UWI/installUWI.sh | bash

#


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


# ==============================================================================
# Configure witty pi functionality
# ==============================================================================


if [[ $configure_wittypi == true ]]; then
  echo
  echo
  echo '>>> Configuring Witty Pi 4 ...'
  echo
  f_configure_wittypi
else
  echo ">>> Skipping configuration of Witty Pi 4 settings"
fi


# echo ">>> Modifying /etc/ntp.conf ..."
# 
# match=$(grep 'driftfile' /etc/ntp.conf)
# match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
# if [[ -z "$match" ]]; then
#     # if line is missing, insert it at end of file
#     echo "driftfile $USB_MOUNT_POINT/var/lib/ntp.drift" >> /etc/ntp.conf
#     echo "Inserted missing line"
# elif [[  "$match" == "#"* ]]; then
#     # if line is commented, insert it after the commented line
#     sed -i 's~^[[:space:]]*#[[:space:]]*driftfile.*~&\ndriftfile '"$USB_MOUNT_POINT"'/var/lib/ntp.drift~ }' /etc/ntp.conf
#     echo "Found commented line, inserting new line after it"
# else
#     # if line exists, replace it
#     sed -i 's#^driftfile.*#driftfile '"$USB_MOUNT_POINT"'/var/lib/ntp.drift# }' /etc/ntp.conf
#     echo "Replaced existing line"
# fi
# 
# touch "$USB_MOUNT_POINT"/var/lib/ntp.drift
# 
# 
# cp /lib/systemd/system/ntp.service /etc/systemd/system

echo
echo ">>> Removing some packages that are not needed ..."
apt remove -y dphys-swapfile
apt remove -y --purge wolfram-engine triggerhappy xserver-common lightdm
apt remove -y --purge bluez
apt autoremove -y --purge



echo 
echo ">>> All logs etc configured for storage on usb drive, in preparation for making sdcard read-only."
echo 

# ==============================================================================
# Set crontab
# ==============================================================================

source $DTUERTPI_DIR/sh_scripts/auto_configure_crontab.sh


# ==============================================================================
# Clean up
# ==============================================================================


echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done. Please reboot your Pi :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
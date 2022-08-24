[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#!/bin/bash
# file: install.sh
#
# This script will install required software for Witty Pi.
# It is recommended to run it in your home directory.
#

# target directories
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_SCRIPTS_DIR="$CURRENT_DIR/install_files"
WITTYPI_DIR="$CURRENT_DIR/wittypi"
DTUERTPI_DIR="$CURRENT_DIR/DTU-ERT-Pi"

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

# PREDEFINED SETTINGS:

# [AUTOSSH]
HOSTNAME=$(hostname)
USER=$HOSTNAME
PORT="2221"
SERVER_IP="192.38.64.71"
SSH_KEY=/root/.ssh/"$HOSTNAME"_sshkey


# include all the functions handling installations
. $INSTALL_SCRIPTS_DIR/install_functions.sh

echo '================================================================================'
echo '|                                                                              |'
echo '|                   DTU-ERT-Pi Software Installation Script                    |'
echo '|                                                                              |'
echo '================================================================================'
# Strongly inspired by WittyPi install script :-)

# check if sudo is used
if [ "$(id -u)" != 0 ]; then
  echo
  echo 'Sorry, you need to run this script with sudo'
  exit 1
fi

# error counter
ERR=0



# ==============================================================================
# Disabling bluetooth, enabling wifi
# ==============================================================================

f_enable_bluetooth $enable_bluetooth
f_enable_wifi $enable_bluetooth

# ==============================================================================
# Checking python version
# ==============================================================================

if [[ check_python_function -eq true ]]; then
    f_check_python_version
fi

if [[ -z install_git || install_git -eq true ]]; then
    echo
    echo
    echo ">>> Installing git..."
    apt-get install -y git || ((ERR++))
fi

# ==============================================================================
# Configuring time related settings
# ==============================================================================

if [[ configure_time_settings -eq true ]]; then
    f_configure_time_settings
fi

# ==============================================================================
# Setting up dhcp client settings
# ==============================================================================

if [[ configure_dhcp_client -eq true ]]; then
    f_configure_dhcp_client
fi

# ==============================================================================
# Installing and configuring dhcp server
# ==============================================================================

if [[ configure_dhcp_server -eq true ]]; then
    f_configure_dhcp_client
fi

# ==============================================================================
# Installing and configuring modem connection
# ==============================================================================

if [[ configure_modem_connection -eq true ]]; then
    f_configure_modem_connection
fi

# ==============================================================================
# Installing and configuring autossh
# ==============================================================================

if [[ configure_autossh -eq true ]]; then
    f_configure_autossh 
fi


# ==============================================================================
# Installing and configuring python dependencies
# ==============================================================================

if [[ install_python_dependencies -eq true ]]; then
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


# ==============================================================================
# Installing and enabling I2C
# ==============================================================================

if [[ enable_I2C -eq true ]]; then
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
# Install DTU-ERT-Pi
# ==============================================================================




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

echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done. Please reboot your Pi :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
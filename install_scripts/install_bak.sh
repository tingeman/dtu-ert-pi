[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#!/bin/bash
# file: install.sh
#
# This script will install required software for Witty Pi.
# It is recommended to run it in your home directory.
#

# check if sudo is used
if [ "$(id -u)" != 0 ]; then
  echo 'Sorry, you need to run this script with sudo'
  exit 1
fi

# target directories
INSTALL_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/install_dir"
WITTYPI_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/wittypi"

# error counter
ERR=0

echo '================================================================================'
echo '|                                                                              |'
echo '|                   DTU-ERT-Pi Software Installation Script                    |'
echo '|                                                                              |'
echo '================================================================================'
# Strongly inspired by WittyPi install script :-)



# ==============================================================================
# Disabling bluetooth, enabling wifi
# ==============================================================================

echo
echo
echo '>>> Disabling bluetooth in /boot/config.txt'

match=$(grep 'dtoverlay=disable-bt' /boot/config.txt)
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" || "$match" == "#"* ]]; then
  echo 'dtoverlay=disable-bt' >> /boot/config.txt
else
  echo 'It seems bluetooth is already disabled.'
fi

echo
echo
echo '>>> enabling wifi in /boot/config.txt'

match=$(grep 'dtoverlay=disable-wifi' /boot/config.txt)
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match"  ]]; then
    echo '# dtoverlay=disable-wifi' >> /boot/config.txt
elif [[ "$match" != "#"* ]]; then
  sed -i "s/^\s*\(dtoverlay=disable-wifi\)/# \1/" /boot/config.txt
else
  echo 'It seems wifi is already enabled.'
fi



# ==============================================================================
# Checking python version
# ==============================================================================

# check if python is installed
# from https://stackoverflow.com/a/33183884/1760389

python_v_expected="3.9"
python_version=$(python3 -V 2>&1 | grep -Po '(?<=Python )\d.\d.\d')
if [[ -z "$python_version" ]]
then
    echo "Python is not installed!" 
    echo "Please install python version 3.9 or higher and rerun this script."
    exit 1
fi

# Set space as the delimiter
oIFS=$IFS
IFS='.'

#Read the split words into an array based on space delimiter
read -a tokens <<< "$python_version"

# reset to default delimiters
IFS="$oIFS"
unset oIFS

# Then reassemble to retain only major version and subversion
py_v="${tokens[0]}.${tokens[1]}"

# compare to expected version
result=$(echo "${py_v} <= ${python_v_expected}" | bc)
if [ $result = 0 ]; then
  echo "Python version is $python_version. Expected at least Python $expected_py_v."
  echo "Please upgrad python, and rerun script!"
  exit 1
fi

echo
echo
echo ">>> Installing git..."
apt-get install -y git || ((ERR++))


# ==============================================================================
# Configuring time related settings
# ==============================================================================

echo
echo
echo ">>> Installing ntp..."
apt-get install -y ntp 

echo
echo
echo ">>> Setting system timezone to UTC..."
echo "Etc/UTC" > /etc/timezone    
dpkg-reconfigure -f noninteractive tzdata

echo
echo
echo ">>> modifying /etc/ntp.conf ..."
grep -q "^restrict 127.0.0.1" /etc/ntp.conf
if [ $? -eq 0 ]; then
  sed -i 's/^\(restrict 127.*\)/# \1/' /etc/ntp.conf 
fi

grep -q "^restrict ::1" /etc/ntp.conf
if [ $? -eq 0 ]; then
  sed -i 's/^\(restrict ::1.*\)/# \1/' /etc/ntp.conf 
fi

echo " " >> /etc/ntp.conf
echo "# Local users may interrogate the ntp server more closely." >> /etc/ntp.conf
echo "restrict 127.0.0.1" >> /etc/ntp.conf
echo "restrict ::1" >> /etc/ntp.conf

grep -q "^restrict 192.168.23.0 mask" /etc/ntp.conf
if [ $? -eq 1 ]; then
    echo " " >> /etc/ntp.conf
    echo "# Clients from this subnet can request time" >> /etc/ntp.conf
    echo "restrict 192.168.23.0 mask 255.255.255.0 nomodify notrap" >> /etc/ntp.conf
fi

grep -q "^server  127.127.1.0" /etc/ntp.conf
if [ $? -eq 1 ]; then
  echo " " >> /etc/ntp.conf
  echo "# Use local clock if upstream server is not available" >> /etc/ntp.conf
  echo "server  127.127.1.0 # local clock" >> /etc/ntp.conf
  echo "fudge   127.127.1.0 stratum 3" >> /etc/ntp.conf
fi

echo
echo
echo ">>> starting ntp service ..."
systemctl start ntp || systemctl restart ntp
if [ $? -eq 1 ]; then
  echo "There was a problem starting the ntp service!"
else
  echo "Success"
fi


# ==============================================================================
# Setting up dhcp client settings
# ==============================================================================

echo
echo
echo '>>> configuring dhcp client settings ...'

# search for 'interfaces eth0' on lines that are not commented
match=$(grep '^[[:blank:]]*[^[:blank:]#]' /etc/dhcpcd.conf | grep 'interface eth0')
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" ]]; then
  echo '' >> /etc/dhcpcd.conf
  echo '# static IP configuration for eth0 so we can run dhcp server:' >> /etc/dhcpcd.conf
  echo 'interface eth0' >> /etc/dhcpcd.conf
  echo 'static ip_address=192.168.23.1/24' >> /etc/dhcpcd.conf
  echo 'static domain_name_servers=1.1.1.1 1.0.0.1 8.8.4.4 8.8.8.8' >> /etc/dhcpcd.conf
  echo 'Done.'
else
  echo 'It seems dhcp client is already configured for eth0.'
  echo 'Please check settings manually!'
fi




# ==============================================================================
# Installing and configuring dhcp server
# ==============================================================================

echo
echo
echo ">>> Installing dhcp server..."
apt-get install -y isc-dhcp-server

echo
echo
echo '>>> configuring dhcp server settings ...'
# search on lines that are not commented
match=$(grep '^[[:blank:]]*[^[:blank:]#]' /etc/default/isc-dhcp-server | grep 'INTERFACESv4.*')
# remove any leading spaces
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" ]]; then
  # if line is missing, add it
  echo " " >> /etc/default/isc-dhcp-server
  echo "INTERFACESv4=\"eth0\"" >> /etc/default/isc-dhcp-server
elif [[ -z $(grep "eth0" <<< $match) ]]; then
  # if line does not contain the correct parameter, comment it and add new line
  sed -i "s/^\s*\(INTERFACESv4.*\)/# \1/" /etc/default/isc-dhcp-server
  echo "INTERFACESv4=\"eth0\"" >> /etc/default/isc-dhcp-server
else
  echo "It seems dhcp server interface is already configured for eth0."
fi


match=$(grep 'authoritative' /etc/dhcp/dhcpd.conf)
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" ]]; then
  # if line is missing, add it
  echo "authoritative;" >> /etc/dhcp/dhcpd.conf
elif [[  "$match" == "#"* ]]; then
  # if line is commented, uncomment it
  sed -i "s/^\s*#\s*\(authoritative.*\)/\1/" /etc/dhcp/dhcpd.conf
else
  echo 'It seems dhcp server is already configured as authoritative'
fi

match=$(grep '^[[:blank:]]*[^[:blank:]#]' /etc/dhcp/dhcpd.conf | grep 'option domain-name .*')
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" ]]; then
  # if line is missing, add it
  echo "option domain-name \"terrameterls\";" >> /etc/dhcp/dhcpd.conf
elif [[ -z $(grep "terrameterls" <<< $match) ]]; then
  # if line does not contain the correct parameter, comment it and add new line below it
  sed -i "s/^\s*\(option domain-name .*\)/# \1/" /etc/dhcp/dhcpd.conf
  sed -i "/^# option domain-name /a option domain-name \"terrameterls\";" /etc/dhcp/dhcpd.conf
else
  echo 'It seems dhcp server is already configured with correct domain name,'
fi

match=$(grep '^[[:blank:]]*[^[:blank:]#]' /etc/dhcp/dhcpd.conf | grep 'option domain-name-servers.*')
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ ! -z "$match" ]]; then
  # if line is not missing, comment it
  sed -i "s/^\s*\(option domain-name-servers.*\)/# \1/" /etc/dhcp/dhcpd.conf
fi

match=$(grep '^[[:blank:]]*[^[:blank:]#]' /etc/dhcp/dhcpd.conf | grep 'subnet 192.168.23.0 .*')
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" ]]; then
  echo " " >> /etc/dhcp/dhcpd.conf
  echo "subnet 192.168.23.0 netmask 255.255.255.0 {" >> /etc/dhcp/dhcpd.conf
  echo "  range 192.168.23.11 192.168.23.30;" >> /etc/dhcp/dhcpd.conf
  echo "  option broadcast-address 192.168.23.255;" >> /etc/dhcp/dhcpd.conf
  echo "}" >> /etc/dhcp/dhcpd.conf
else
  echo 'It seems dhcp server is already configured for subnet 192.168.23.0'
  echo 'Please check settings in /etc/dhcp/dhcpd.conf'
fi

match=$(grep '^[[:blank:]]*[^[:blank:]#]' /etc/dhcp/dhcpd.conf | grep 'host LS209110003 .*')
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" ]]; then
  echo " " >> /etc/dhcp/dhcpd.conf
  echo "host LS209110003 {" >> /etc/dhcp/dhcpd.conf
  echo "  hardware ethernet 02:AD:BE:EF:03:00;" >> /etc/dhcp/dhcpd.conf
  echo "  fixed-address 192.168.23.10;" >> /etc/dhcp/dhcpd.conf
  echo "}" >> /etc/dhcp/dhcpd.conf
else
  echo 'It seems dhcp server is already configured for host LS209110003.'
  echo 'Please check settings in /etc/dhcp/dhcpd.conf'
fi


echo ' '
echo ' '
echo '>>> Implementing fix for restart of dhcp server ...'

sudo cp /run/systemd/generator.late/isc-dhcp-server.service /etc/systemd/system

match=$(sed -n '/^\[Service\]/,/^$/ { /Restart=/p  }' /etc/systemd/system/isc-dhcp-server.service)
if [[ -z "$match" ]]; then
  # if line is missing, insert it after the [Service] tag
  sed -i '/^\[Service\]/,/^$/ { s/^\[Service\].*/&\nRestart=on-failure/  }' /etc/systemd/system/isc-dhcp-server.service
  echo "Inserted missing line"
elif [[  "$match" == "#"* ]]; then
  # if line is commented, insert it after the commented line
  sed -i '/^\[Service\]/,/^$/ { s/^[[:space:]]*#[[:space:]]*Restart.*/&\nRestart=on-failure/  }' /etc/systemd/system/isc-dhcp-server.service
  echo "Found commented line, inserting new line after it"
else
  # if line exists, replace it
  sed -i '/^\[Service\]/,/^$/ { s/^Restart=.*/Restart=on-failure/ }' /etc/systemd/system/isc-dhcp-server.service
  echo "Replaced existing line"
fi

match=$(sed -n '/^\[Service\]/,/^$/ { /RestartSec=/p  }' /etc/systemd/system/isc-dhcp-server.service)
if [[ -z "$match" ]]; then
  # if line is missing, insert it after the Restart= tag
  sed -i '/^\[Service\]/,/^$/ { s/^Restart=.*/&\nRestartSec=5/  }' /etc/systemd/system/isc-dhcp-server.service
  echo "Inserted missing line"
elif [[  "$match" == "#"* ]]; then
  # if line is commented, insert it after the commented line
  sed -i '/^\[Service\]/,/^$/ { s/^[[:space:]]*#[[:space:]]*RestartSec=.*/&\nRestartSec=5/  }' /etc/systemd/system/isc-dhcp-server.service
  echo "Found commented line, inserting new line after it"
else
  # if line exists, replace it
  sed -i '/^\[Service\]/,/^$/ { s/^RestartSec=.*/RestartSec=5/ }' /etc/systemd/system/isc-dhcp-server.service
  echo "Replaced existing line"
fi

match=$(sed -n '/^\[Service\]/,/^$/ { /ExecStartPre=/p  }' /etc/systemd/system/isc-dhcp-server.service)
if [[ -z "$match" ]]; then
  # if line is missing, insert it at after ExecStart tag
  sed -i '/^\[Service\]/,/^$/ { s/ExecStart=.*/&\nExecStartPre=\/bin\/sleep 10/ }' /etc/systemd/system/isc-dhcp-server.service
  echo "Inserted missing line"
elif [[  "$match" == "#"* ]]; then
  # if line is commented, insert it after the commented line
  sed -i '/^\[Service\]/,/^$/ { s/^[[:space:]]*#[[:space:]]*ExecStartPre=.*/&\nExecStartPre=\/bin\/sleep 10/  }' /etc/systemd/system/isc-dhcp-server.service
  echo "Found commented line, inserting new line after it"
else
  # if line exists, replace it
  sed -i '/^\[Service\]/,/^$/ { s/^ExecStartPre=.*/ExecStartPre=\/bin\/sleep 10/ }' /etc/systemd/system/isc-dhcp-server.service
  echo "Replaced existing line"
fi

match=$(grep '^[[:blank:]]*[^[:blank:]#]' /etc/systemd/system/isc-dhcp-server.service | grep '^\[Install\]')
if [[ -z "$match" ]]; then
  # Section does not exist, insert everything directly...
  echo " " >> /etc/systemd/system/isc-dhcp-server.service
  echo "[Install]" >> /etc/systemd/system/isc-dhcp-server.service
  echo "WantedBy=multi-user.target" >> /etc/systemd/system/isc-dhcp-server.service
else
  # Section does exist, do conditional insert
  match=$(sed -n '/^\[Install\]/,/^$/ { /WantedBy=/p  }' /etc/systemd/system/isc-dhcp-server.service)
  if [[ -z "$match" ]]; then
    # if line is missing, insert it at start of section
    sed -i '/^\[Service\]/,/^$/ { s/^\[Install\].*/&\nWantedBy=multi-user.target/  }' /etc/systemd/system/isc-dhcp-server.service
    echo "Inserted missing line"
  elif [[  "$match" == "#"* ]]; then
    # if line is commented, insert it after the commented line
    sed -i '/^\[Service\]/,/^$/ { s/^[[:space:]]*#[[:space:]]*WantedBy=.*/&\nWantedBy=multi-user.target/  }' /etc/systemd/system/isc-dhcp-server.service
    echo "Found commented line, inserting new line after it"
  else
    # if line exists, replace it
    sed -i '/^\[Service\]/,/^$/ { s/^WantedBy=.*/WantedBy=multi-user.target/ }' /etc/systemd/system/isc-dhcp-server.service
    echo "Replaced existing line"
  fi
fi


echo '>>> Restarting dhcp server ...'
sudo systemctl daemon-reload
sudo service isc-dhcp-server stop
sudo service isc-dhcp-server start
sudo systemctl disable isc-dhcp-server
sudo systemctl enable isc-dhcp-server

if [ $? -eq 1 ]; then
  echo "There was a problem starting dhcp server!"
else
  echo "Success"
fi

# ==============================================================================
# Installing and configuring modem connection
# ==============================================================================

echo
echo
echo ">>> Installing packages related to modem operation..."
apt-get install -y libpcap0.8 libuniconf4.6 libwvstreams4.6-base libwvstreams4.6-extras ppp wvdial minicom usb-modeswitch || ((ERR++))

cp "$INSTALL_SCRIPTS_DIR/wvdial.conf" /etc/wvdial.conf
echo "Check if settings are correct in /etc/wvdial.conf"

cp "$INSTALL_SCRIPTS_DIR/ppp.conf" /etc/modules-load.d/ppp.conf
echo "Created /etc/modules-load.d/ppp.conf"

cp "$INSTALL_SCRIPTS_DIR/wait-dialup-hardware" /etc/ppp/wait-dialup-hardware
chmod 0755 /etc/ppp/wait-dialup-hardware
echo "Created /etc/ppp/wait-dialup-hardware"

cp "$INSTALL_SCRIPTS_DIR/wvdial" /etc/ppp/peers/wvdial
echo "Created /etc/ppp/peers/wvdial"

match=$(grep '^[[:blank:]]*[^[:blank:]#]' /etc/network/interfaces | grep '^iface ppp0')
if [[ -z "$match" ]]; then
  # Section does not exist, insert everything directly...
  read -r -d '' out_str <<-EOF


# start cellular connection
# pre-up
#   wait for at max 30 seconds before connecting for the modem to become connec$
#   Since modem  might not be available immediately
#   wait 30 more seconds for the cellular connection to become active
auto ppp0
iface ppp0 inet wvdial
  pre-up /etc/ppp/wait-dialup-hardware ttyUSB2 30
  pre-up sleep 30
  post-up echo "Cellular (ppp0) is online"
EOF

  echo "$out_str" >> /etc/network/interfaces

else
  # Section does exist...
  echo "It seems ppp0 interface is already configured... skipping this step."
fi


# ==============================================================================
# Installing and configuring autossh
# ==============================================================================

HOSTNAME=$(hostname)
USER=$HOSTNAME
PORT="2221"
SERVER_IP="192.38.64.71"
SSH_KEY=/root/.ssh/"$HOSTNAME"_sshkey

echo
echo
echo ">>> Installing autossh..."
apt-get install -y autossh

echo
echo
echo '>>> Generating ssh public-private key relationship...'
mkdir /root/.ssh

if [ -f $SSHKEY ]; then
   echo "It seems ssh key already exists... skipping this step."
else
   ssh-keygen -b 2048 -t rsa -f $SSH_KEY -q -N ""
   echo "Created ssh key."
fi


# ExecStart=/usr/bin/autossh -f -M 0 -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -NR PORT:127.0.0.1:22 USER@SERVER_IP -p 22 -i SSH_KEY
cp "$INSTALL_SCRIPTS_DIR/autossh-byg-cdata1-tunnel.service" /etc/systemd/system/autossh-byg-cdata1-tunnel.service

sed -i '/ExecStart=\/usr\/bin\/autossh/s/PORT/'"$PORT"'/' /etc/systemd/system/autossh-byg-cdata1-tunnel.service
sed -i '/ExecStart=\/usr\/bin\/autossh/s/USER/'"$USER"'/' /etc/systemd/system/autossh-byg-cdata1-tunnel.service
sed -i '/ExecStart=\/usr\/bin\/autossh/s/SERVER_IP/'"$SERVER_IP"'/' /etc/systemd/system/autossh-byg-cdata1-tunnel.service

# see this https://stackoverflow.com/a/27787551/1760389 for explanation of using ~ below
sed -i '/ExecStart=\/usr\/bin\/autossh/s~SSH_KEY~'"$SSH_KEY"'~' /etc/systemd/system/autossh-byg-cdata1-tunnel.service

echo "Created /etc/systemd/system/autossh-byg-cdata1-tunnel.service"

systemctl daemon-reload
systemctl start autossh-byg-cdata1-tunnel.service
systemctl enable autossh-byg-cdata1-tunnel.service
echo "Started the autossh-byg-cdata1-tunnel.service"
echo " "
echo "You must manually set up the server to accept the ssh connection!"



# ==============================================================================
# Installing and configuring python dependencies
# ==============================================================================

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



# ==============================================================================
# Installing and enabling I2C
# ==============================================================================

echo
echo
echo '>>> Installing i2c-tools'
if hash i2cget 2>/dev/null; then
  echo 'Seems i2c-tools is installed already, skip this step.'
else
  apt-get install -y i2c-tools || ((ERR++))
fi

# enable I2C on Raspberry Pi
echo
echo
echo '>>> Enable I2C'
if grep -q 'i2c-bcm2708' /etc/modules; then
  echo 'Seems i2c-bcm2708 module already exists, skip this step.'
else
  echo 'i2c-bcm2708' >> /etc/modules
fi
if grep -q 'i2c-dev' /etc/modules; then
  echo 'Seems i2c-dev module already exists, skip this step.'
else
  echo 'i2c-dev' >> /etc/modules
fi

i2c1=$(grep 'dtparam=i2c1=on' /boot/config.txt)
i2c1=$(echo -e "$i2c1" | sed -e 's/^[[:space:]]*//')
if [[ -z "$i2c1" || "$i2c1" == "#"* ]]; then
  echo 'dtparam=i2c1=on' >> /boot/config.txt
else
  echo 'Seems i2c1 parameter already set, skip this step.'
fi

i2c_arm=$(grep 'dtparam=i2c_arm=on' /boot/config.txt)
i2c_arm=$(echo -e "$i2c_arm" | sed -e 's/^[[:space:]]*//')
if [[ -z "$i2c_arm" || "$i2c_arm" == "#"* ]]; then
  echo 'dtparam=i2c_arm=on' >> /boot/config.txt
else
  echo 'Seems i2c_arm parameter already set, skip this step.'
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
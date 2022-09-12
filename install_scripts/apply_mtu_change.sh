#!/bin/bash

[ -z $BASH ] && { exec bash "$0" "$@" || exit; }

# error counter
ERR=0

# check if sudo is used
if [ "$(id -u)" != 0 ]; then
  echo
  echo 'Sorry, you need to run this script with sudo'
  exit 1
fi

echo " "
echo ">>> Updating /etc/ppp/options with new MTU setting..."

match=$(grep '^[[:blank:]#]*mtu' /etc/ppp/options)
match=$(echo -e "$match" | sed -e 's/^[[:space:]]*//')
if [[ -z "$match" ]]; then
    # if line is missing, insert it 
    echo "mtu 1200" >> /etc/ppp/options
    echo "Inserted missing line"
elif [[  "$match" == "#"* ]]; then
    # if line is commented, replace it
    sed -i 's/^[[:space:]]*#[[:space:]]*mtu .*/mtu 1200/' /etc/ppp/options
    echo "Found commented line, and replaced it"
else
    # if line exists, replace it
    #sed -i "s/^\s*\(mtu .*\)/mtu 1200/" /etc/ppp/options
    sed -i "s/^\s*mtu .*/mtu 1200/" /etc/ppp/options
    echo 'Found existing line and replaced it.'
fi

echo "done"
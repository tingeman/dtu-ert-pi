#!/bin/bash

if [[ -z $SCRIPTS_DIR ]]; then
    SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

source "$SCRIPTS_DIR/script_settings"

/usr/bin/ssh-copy-id -i "$SSHKEY".pub $SERVER

if [[ $? -eq 0 ]]; then
    echo "SSH key has been added to the authorized_keys of the host."
    echo "Test access with the command: ssh -i $SSHKEY $SERVER"
else
    echo "Could not add key to hosts authorized keys!"
    echo "Please do it manually."
fi



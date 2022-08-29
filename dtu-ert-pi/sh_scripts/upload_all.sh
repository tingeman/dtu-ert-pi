#!/bin/bash

# If this script is sourced from the install script, the variable
# DTUERTPI_DIR will be set and can be used as the base for determining
# folder structure.
# If not set, get the current directory from the bash environment
if [[ -z $DTUERTPI_DIR ]]; then
  SH_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
  SH_SCRIPTS_DIR="$DTUERTPI_DIR"/sh_scripts
fi

# import settings
source "$SH_SCRIPTS_DIR"/script_settings

echo "Uploading /root/ files..."
$USRBIN/rsync -rtlDz --timeout=300 -e "ssh -i $SSHKEY" --exclude "/.*" --chmod "Da=rw,Fa=rw" --mkpath /root/ $SSHUSER@$SERVER_IP:$UPLDESTDIR/home_root/ 2>> $LOGDIR/uploadlog
echo "Uploading logs..."
$USRBIN/rsync -rtlDz --timeout=300 -e "ssh -i $SSHKEY" --exclude "/.*" --chmod "Da=rw,Fa=rw" --mkpath $LOGDIR/ $SSHUSER@$SERVER_IP:$UPLDESTDIR/logs/ 2>> $LOGDIR/uploadlog
echo "Uploading crontab backups..."
$USRBIN/rsync -rtlDz --timeout=300 -e "ssh -i $SSHKEY" --exclude "/.*" --chmod "Da=rw,Fa=rw" --mkpath $CRONTABDIR/ $SSHUSER@$SERVER_IP:$UPLDESTDIR/crontabs/ 2>> $LOGDIR/uploadlog
echo "Uploading crontab backups..."
$USRBIN/rsync -rtlDz --timeout=300 -e "ssh -i $SSHKEY" --chmod "Da=rw,Fa=rw" --exclude "RawData" --mkpath $UPLSOURCEDIR $SSHUSER@$SERVER_IP:$UPLDESTDIR 2>> $LOGDIR/uploadlog

echo "Done!"

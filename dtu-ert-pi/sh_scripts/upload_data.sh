#!/bin/bash

####################################################################
#        UPLOAD to BYG-server
#
#
#        Joseph Doetsch - 2013-05-04
#        Thomas Ingeman-Nielsen - 2021-05-27
#
####################################################################

# rsync arguments
# 
# -a, --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
# -r, --recursive             recurse into directories
# -l, --links                 copy symlinks as symlinks
# -p, --perms                 preserve permissions
# -t, --times                 preserve modification times
# -g, --group                 preserve group
# -o, --owner                 preserve owner (super-user only)
# -D                          same as --devices --specials
#     --devices               preserve device files (super-user only)
#     --specials              preserve special files
#     --timeout=SECONDS       set I/O timeout in seconds
# -e, --rsh=COMMAND           specify the remote shell to use
#     --exclude=PATTERN       exclude files matching PATTERN


SH_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# OR USE THIS(?): SH_SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# import settings
source "$SH_SCRIPTS_DIR"/script_settings


test_connectivity()
{
    ssh_ok=0
    
    $BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"` "UPL: Trying $SSH" >> $LOG_DIR/uploadlog   
    HOST=`$SSH hostname 2>> $LOG_DIR/uploadlog`
    
    if [ $? -eq 0 ]
    then
        ssh_ok=1
        $BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"` "UPL: Connected OK to $HOST" >> $LOG_DIR/uploadlog   
    else
        ssh_ok=0
        $BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"` "UPL: Failed to connect" >> $LOG_DIR/uploadlog   
    fi
}

start_upload()
{
    if [ -d $UPLSOURCEDIR ]
    then
        $BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"` "UPL: Start upload" >> $LOG_DIR/uploadlog
        $USRBIN/rsync -rtlDz --timeout=300 -e "ssh -i $SSHKEY" --chmod "Da=rw,Fa=rw" --exclude "RawData" --mkpath $UPLSOURCEDIR $SSHUSER@$SERVER_IP:$UPLDESTDIR 2>> $LOG_DIR/uploadlog
        # --chmod "Da=rw,Fa=rw":    set destination permissions so all users can read/write/delete the files

        if [ $? -eq 0 ]
        then
             upl_ok=1
             $BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"` "UPL: Upload done" >> $LOG_DIR/uploadlog
        else
            upl_ok=0
            $BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"`  "UPL: Upload failed." >> $LOG_DIR/uploadlog   
        fi
    else
        $BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"` "UPL: No upload source available" >> $LOG_DIR/uploadlog
    fi
}


# This is the main program

$BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"` "UPL: Starting upload to BYG" >> $LOG_DIR/uploadlog

test_connectivity

if [ $ssh_ok -eq 1 ]
then
    start_upload
else
    $BIN/echo `date "+%Y-%m-%d %H:%M:%S(%z)"` "UPL: Could not connect" >> $LOG_DIR/uploadlog   
fi


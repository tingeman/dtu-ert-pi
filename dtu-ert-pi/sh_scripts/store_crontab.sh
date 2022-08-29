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

# store curren crontab in temporary file
crontab -l 2>/dev/null > $CRONTABDIR/crontab_$HOSTNAME"_"`date "+%Y%m%d_%H%M%S(%Z)"`.txt


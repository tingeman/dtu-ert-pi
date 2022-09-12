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

if [[ $# -gt 0 ]]; then
  if [[ -f $1 ]]; then
    CRONTAB_TEMPLATE=$1
  elif [[ -f "$SH_SCRIPTS_DIR/template_files/$1" ]]; then
    CRONTAB_TEMPLATE="$SH_SCRIPTS_DIR/template_files/$1"
  fi
fi

if [[ -z $CRONTAB_TEMPLATE ]]; then
  # Different crontab template files are available.
  # Add more custom templates in dtu-ert-pi/sh_scripts/template_files
  #CRONTAB_TEMPLATE=$SH_SCRIPTS_DIR/template_files/crontab_template.txt
  CRONTAB_TEMPLATE=$SH_SCRIPTS_DIR/template_files/crontab_template_testing.txt
  #CRONTAB_TEMPLATE=$SH_SCRIPTS_DIR/template_files/crontab_template_shutdown.txt
fi

echo " "
echo "Updating crontab using: $CRONTAB_TEMPLATE"
echo " "

# import settings
source "$SH_SCRIPTS_DIR"/script_settings
source "$WITTYPI_DIR"/wittyPi.conf

# store curren crontab in temporary file
(crontab -l 2>/dev/null || true) > "$SH_SCRIPTS_DIR"/cron_tmp.txt

SED_SECTION='/^.*BEGIN AUTO CONFIGURE SECTION.*$/,/END AUTO CONFIGURE SECTION.*$/'
# remove AUTO CONFIGURE section
sed -i "$SED_SECTION"'d' "$SH_SCRIPTS_DIR"/cron_tmp.txt

# remove last line of file if blank
sed -i -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$SH_SCRIPTS_DIR"/cron_tmp.txt
# then add a blank line before AUTO CONFIGURE section
echo >> "$SH_SCRIPTS_DIR"/cron_tmp.txt

# reinsert AUTO CONFIGURE section from template file at end of crontab
cat "$CRONTAB_TEMPLATE" >> "$SH_SCRIPTS_DIR"/cron_tmp.txt

# search and replace placeholder text
sed -i "$SED_SECTION"' {s#WITTYPI_DIR#'"$WITTYPI_DIR"'#}' "$SH_SCRIPTS_DIR"/cron_tmp.txt
#sed -i "$SED_SECTION"' {s#WITTYPI_LOG_FILE#'"$WITTYPI_LOG_FILE"'#}' "$SH_SCRIPTS_DIR"/cron_tmp.txt
sed -i "$SED_SECTION"' {s#SCHEDULE_LOG_FILE#'"$SCHEDULE_LOG_FILE"'#}' "$SH_SCRIPTS_DIR"/cron_tmp.txt
sed -i "$SED_SECTION"' {s#DTUERTPI_DIR#'"$DTUERTPI_DIR"'#}' "$SH_SCRIPTS_DIR"/cron_tmp.txt

# Install crontab...
cat "$SH_SCRIPTS_DIR"/cron_tmp.txt | /usr/bin/crontab -

# Remove temporary file
rm "$SH_SCRIPTS_DIR"/cron_tmp.txt
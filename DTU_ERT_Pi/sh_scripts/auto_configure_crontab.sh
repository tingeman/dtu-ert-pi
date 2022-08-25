
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
source "$WITTYPI_DIR"/wittyPi.conf

# store curren crontab in temporary file
(crontab -l 2>/dev/null || true) > "$SH_SCRIPTS_DIR"/cron_tmp.txt

SED_SECTION='/^.*BEGIN AUTO CONFIGURE SECTION.*$/,/END AUTO CONFIGURE SECTION.*$/'
# remove AUTO CONFIGURE section
sed -i "$SED_SECTION"'d' cron_tmp.txt

# reinsert AUTOCONFIGURE section from template file
cat "$DTUERTPI_DIR"/sh_scripts/template_files/crontab_template.txt >> cron_tmp.txt

# search and replace placeholder text
sed -i "$SED_SECTION"' {s#WITTYPI_DIR#'"$WITTYPI_DIR"'#}' cron_tmp.txt
sed -i "$SED_SECTION"' {s#WITTYPI_LOG_FILE#'"$WITTYPI_LOG_FILE"'#}' cron_tmp.txt
sed -i "$SED_SECTION"' {s#DTUERTPI_DIR#'"$DTUERTPI_DIR"'#}' cron_tmp.txt

cat "$SH_SCRIPTS_DIR"/cron_tmp.txt | /usr/bin/crontab -
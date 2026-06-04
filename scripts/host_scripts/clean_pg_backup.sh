#!/bin/bash


######################
### clean backups ####
######################
DAYS_TO_KEEP=21
WEEKS_TO_KEEP=6
BACKUP_DIR="/xdata-archive/pg_backup/"
# keeps sunday backups

echo -e "\nCleaning old backups:"

echo "Days to keep: $DAYS_TO_KEEP"
echo "Weeks to keep: $WEEKS_TO_KEEP"
TOTAL_DAYS_TO_KEEP=$(($WEEKS_TO_KEEP*7))
find /xdata-archive/pg_backup/ -type f -mtime +$TOTAL_DAYS_TO_KEEP # -delete
find /xdata-archive/pg_backup/* type d -mtime +$TOTAL_DAYS_TO_KEEP # | xargs rm -rf

# Change -ne 7 to change the day that is kept:
# Which day to take the weekly backup from (1-7 = Monday-Sunday)
find /xdata-archive/pg_backup/ -mindepth 1 -type f -mtime +"$DAYS_TO_KEEP" \
  -exec sh -c '
    for f; do
      # %u: day of week (1=Mon ... 7=Sun)
      if [ "$(date -r "$f" +%u)" -ne 7 ]; then
        echo "Removing file: rm -f $f"
        rm -f "$f"
      fi
    done
  ' sh {} +

# Change -ne 7 to change the day that is kept:
# Which day to take the weekly backup from (1-7 = Monday-Sunday)
find /xdata-archive/pg_backup/ -mindepth 1 -type d -empty -mtime +"$DAYS_TO_KEEP" \
  -exec sh -c '
    for d; do
      if [ "$(date -r "$d" +%u)" -ne 7 ]; then
         echo "Removing directory: rmdir $d"
         rmdir "$d"
      fi
    done
  ' sh {} +

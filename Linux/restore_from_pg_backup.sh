#!/usr/bin/env bash



echo "This script assumes the postgres database is located at /xnat-data/postgresql"
read -p 'This will stop XNAT, delete the current database and replace it with an older version. Do you wish to Continue? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi

echo "stopping XNAT..."
docker stack rm xnat-stack
sleep 60

echo "making a backup of current postgresql directory to /xnat-data/postgresql_backup"
if [ -d "/xnat-data/postgresql_backup" ]; then
        read -p 'Backup copy of the database already exists- /xnat-data/postgresql_backup. Overwrite and Continue? y/n ' cont
      if [ "$cont" != "y" ]
      then
        exit
      else
        rm -r /xnat-data/postgresql_backup/
      fi

fi

mv /xnat-data/postgresql/postgres-data/ /xnat-data/postgresql_backup/
# remove old database contents
mkdir -p /xnat-data/postgresql/postgres-data/
ls /xnat-data/postgresql/postgres-data/
mkdir /xnat-data/pg_backup

read -p 'Copy either xnat.sql.gz, xnat.custom or your directory-format backup directory "xnat" from /xnat-data/xnat/scripts/pg_backup/[date] to /xnat-data/pg_backup. Press y to continue after copying file? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi

continue=false

if [ -d "/xnat-data/pg_backup/xnat" ]; then
  echo "Backup directory found: /xnat-data/pg_backup/xnat"
  continue=true
fi
if [ -f "/xnat-data/pg_backup/xnat.custom" ]; then
  echo "Custom backup file found: /xnat-data/pg_backup/xnat.custom"
  continue=true
fi
if [ -f "/xnat-data/pg_backup/xnat.sql.gz" ]; then
  echo "Plain backup directory found: /xnat-data/pg_backup/xnat.sql.gz"
  continue=true
fi
if [ "$continue" = false ]; then
  echo "No backup found"
  exit
fi

# editing
sed -i  "s|#WINX- ./volume/postgres-data|- /xnat-data/pg_backup|g"  ../docker-compose.yml
echo "##############################"
echo "Do NOT stop the script early. Allow XNAT to restart fully and this script to finish."
echo "##############################"
echo "n" | ./restart.sh

#comment out so if restarting does not replace current XNAT
sed -i  "s|- /xnat-data/pg_backup|#WINX- ./volume/postgres-data|g"  ../docker-compose.yml
echo "##############################"
echo "Restore finished."

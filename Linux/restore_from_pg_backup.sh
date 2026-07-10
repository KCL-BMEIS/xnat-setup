#!/usr/bin/env bash

linux_dir=$(dirname "$0")
cd "$linux_dir"
cd ..
install_dir=$(pwd)
source "$install_dir/xnat.cfg"



echo "The xnat-data path is taken from xnat.cfg. The postgresql database path is set to: $xnat_data/postgresql"
read -p 'This will stop XNAT, delete the current database and replace it with an older version. Do you wish to Continue? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi


if docker stack ls --format '{{.Name}}' | grep -qx 'xnat-stack'; then
  echo "XNAT running, stopping XNAT..."
  docker stack rm xnat-stack
  sleep 60
fi



echo "making a backup of current postgresql directory to $xnat_data/postgresql_backup"
if [ -d "$xnat_data/postgresql_backup" ]; then
        read -p "Backup copy of the database already exists- $xnat_data/postgresql_backup. Overwrite and Continue? y/n " cont
      if [ "$cont" != "y" ]
      then
        exit
      else
        rm -r $xnat_data/postgresql_backup/
      fi

fi

mv $xnat_data/postgresql/postgres-data/ $xnat_data/postgresql_backup/
# remove old database contents
mkdir -p $xnat_data/postgresql/postgres-data/
ls $xnat_data/postgresql/postgres-data/
mkdir $xnat_data/pg_backup

read -p "Copy either xnat.sql.gz, xnat.custom or your directory-format backup directory 'xnat' from $xnat_data/xnat/scripts/pg_backup/[date] to $xnat_data/pg_backup. Press y to continue after copying file? y/n " cont
if [ "$cont" != "y" ]
then
  exit
fi

continue=false

if [ -d "$xnat_data/pg_backup/xnat" ]; then
  echo "Backup directory found: $xnat_data/pg_backup/xnat"
  continue=true
fi
if [ -f "$xnat_data/pg_backup/xnat.custom" ]; then
  echo "Custom backup file found: $xnat_data/pg_backup/xnat.custom"
  continue=true
fi
if [ -f "$xnat_data/pg_backup/xnat.sql.gz" ]; then
  echo "Plain backup directory found: $xnat_data/pg_backup/xnat.sql.gz"
  continue=true
fi
if [ "$continue" = false ]; then
  echo "No backup found"
  exit
fi

# editing
sed -i  "s|#WINX- ./volume/postgres-data|- $xnat_data/pg_backup|g"  "$install_dir/docker-compose.yml"
echo "##############################"
echo "Do NOT stop the script early. Allow XNAT to restart fully and this script to finish."
echo "##############################"
cd Linux
echo "n" | ./restart.sh

#comment out so if restarting does not replace current XNAT
sed -i  "s|- $xnat_data/pg_backup|#WINX- ./volume/postgres-data|g"  "$install_dir/docker-compose.yml"
echo "##############################"
echo "Restore finished. Please be patient as database may still be being restored"

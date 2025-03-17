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
cp -r /xnat-data/postgresql /xnat-data/postgresql_backup
mkdir /xnat-data/pg_backup

read -p 'Copy your xnat.sql.gz file from /xnat-data/xnat/scripts/pg_backup/[date] to /xnat-data/pg_backup. Press y to continue after copying file? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi

# editing
sed -i  "s|#WINX- ./volume/postgres-data|- /xnat-data/pg_backup|g"  ../docker-compose.yml
echo "##############################"
echo "Do NOT stop the script early. Allow XNAT to restart fully and this script to finish."
echo "##############################"
./restart.sh

#comment out so if restarting does not replace current XNAT
sed -i  "s|- /xnat-data/pg_backup|#WINX- ./volume/postgres-data|g"  ../docker-compose.yml
echo "##############################"
echo "Restore finished."

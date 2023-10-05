#!/usr/bin/env bash

dos2unix /data/scripts/clean_logs.sh
dos2unix /data/xnat/*
dos2unix /data/scripts/*
dos2unix /data/scripts/cronjobs/*
dos2unix /opt/scripts/*
dos2unix /data/xnat/home/xnat.cfg
dos2unix /data/xnat/home/config/*


apt-get -yq update
apt-get -yq upgrade


source /data/xnat/home/xnat.cfg
#need to delete evrything in case of replacing old plugins in a saved container
rm -f /data/xnat/home/plugins/*.jar
cp /data/scripts/plugins/*.jar /data/xnat/home/plugins/
## if there is a logo...
cp /data/scripts/logo.png /usr/local/tomcat/webapps/ROOT/images/

echo 'Starting setup script for '"$site_name"''  > /data/scripts/logs/setup.log

chmod 600 /data/xnat/home/xnat.cfg
chmod 600 /data/xnat/home/.bash_profile


#ensure postgresql started

sleep 100

##### PGRESTORE ON WINDOWS! HAve to do beforehand ####
if [ -d "/pg_backup" ]; then 
		psql_pwd="$(head /run/secrets/pgpass)"
    export PGPASSWORD="$psql_pwd"
		for folder in /pg_backup/*
		do
		   sql_file=$(find "$folder" -exec stat \{} --printf="%n \n" \; | sort -n -r  | head -1) 
		done
		if [[ $sql_file = *".sql.gz"* ]]; then	
			gunzip -k -f $sql_file
			sql_unpacked="${sql_file/.gz/}" 
			echo "Windows: Backup database file detected. Restoring database using  $sql_unpacked" >> /data/scripts/logs/setup.log
			psql -h xnat-db -p 5432 -U xnat  -f $sql_unpacked
		fi
fi

echo 'Starting Server' >> /data/scripts/logs/setup.log
/usr/local/tomcat/bin/startup.sh &
#/usr/local/tomcat/bin/catalina.sh run &



echo 'Starting cron' >> /data/scripts/logs/setup.log
mkdir /data/scripts/access_logs
mkdir /data/scripts/pg_backup
service cron start
crontab -u root /data/scripts/cronjobs/cronjobs.txt
touch /var/log/cron.log


echo 'Waiting for server to respond' >> /data/scripts/logs/setup.log

# it must be restarting server
if compgen -G "/data/xnat/home/logs/access*.log" > /dev/null; then
   #chown -R xnat:xnat /data
   chmod -R 775 /data/xnat/home/plugins/

   ##wait for war to unpack and database to build
   echo "Restarting Server" >> /data/scripts/logs/setup.log
   sleep 200

else
    ##wait for war to unpack and database to build


    sleep 100

    a=0
    while [ $a -lt 1 ]
    do
    response=$(curl -u admin:admin -X GET 'http://localhost:8080/data/users')
    echo "Response from curl: $response"
    if [[ $response = *"admin"* ]]; then
      a=10
      echo "############################"
    else
      echo "ERROR DETECTED" 
      a=0
      sleep 5
    fi
    done


  echo "Server Started" >> /data/scripts/logs/setup.log

  echo "Initial Setup of Server"

  ### CREATE PROJECT
  curl -u admin:admin -X PUT --header 'Accept: application/json' 'http://localhost:8080/data/archive/projects/'"$site_name"''

  echo "Creating Users"


  #CREATE ADMIN USER
  curl -u admin:admin -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "email": "'"$xnat_admin_email"'",
    "enabled": true,
    "verified": true,
    "firstName": "xnat",
    "lastName": "xnat",
    "password": "ignored",
    "confirmPassword":"ignored"
    "username": "'"$xnat_admin_user"'"
  }' 'http://localhost:8080/xapi/users'  > /data/scripts/logs/technicalsetup.log
  #ADD ADMIN USER TO HOSPITAL PROJECT
  curl -u admin:admin -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d '[
    "ALL_DATA_ADMIN",
    "'"$site_name"'_owner"
  ]' 'http://localhost:8080/xapi/users/'"$xnat_admin_user"'/groups'  >> /data/scripts/logs/technicalsetup.log
  curl -u admin:admin -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d '[
    "Administrator",
    "DataManager",
    "SiteUser"
  ]' 'http://localhost:8080/xapi/users/'"$xnat_admin_user"'/roles'  >> /data/scripts/logs/technicalsetup.log


  echo "Installing Config File" >> /data/scripts/logs/setup.log
  #### INSTALL SITECONFIG
  settings="$(cat /data/xnat/home/siteConfig.txt)"
  curl -u admin:admin  -X POST --header 'Content-Type: application/json' --header 'Accept: */*' -d "$settings"  'http://localhost:8080/xapi/siteConfig' >> /data/scripts/logs/technicalsetup.log

  #enable event service:
  curl -u admin:admin  -X PUT "http://localhost:8080/xapi/events/prefs" -H  "accept: */*" -H  "Content-Type: application/json" -d "{  \"enabled\": true}"

   ## configure docker if installed:
   curl -u admin:admin  'http://localhost:8080/xapi/docker/server' -H 'Content-Type: application/json'  --data-raw '{"name":"Local socket","host":"unix:///var/run/docker.sock","cert-path":"","swarm-mode":true,"path-translation-xnat-prefix":"/data/xnat","path-translation-docker-prefix":"/xnat-data/xnat","pull-images-on-xnat-init":true,"container-user":"","auto-cleanup":true}'


  echo "Disabling admin and guest users" >> /data/scripts/logs/setup.log
  #DISABLE ADMIN & GUEST
  curl -u admin:admin -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' 'http://localhost:8080/xapi/users/guest/enabled/false' >> /data/scripts/logs/technicalsetup.log
  #cannot set password, well not easily.
  #curl -u $xnat_admin_user:$xnat_admin_pwd -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' 'http://localhost:8080/xapi/users/admin/enabled/false' >> /data/scripts/logs/technicalsetup.log



fi



while true
do
    
    #### check import_data folder
    chmod 775 /data/scripts/import_dicoms.sh
    echo "Running initial checks."  >> /data/scripts/logs/setup.log
    bats /data/scripts/run_linux_tests.bats >> /data/scripts/logs/setup.log
    echo "Starting import script. XNAT is ready to use" >> /data/scripts/logs/setup.log
    #sleep 100000000000
    /bin/bash /data/scripts/import_dicoms.sh  >> /data/scripts/logs/import_dicoms.log
    sleep 30
    

done

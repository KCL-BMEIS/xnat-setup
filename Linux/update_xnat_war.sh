#!/usr/bin/env bash

echo "This script assumes xnat_home is located at /xnat-data/xnat. Edit the script before running if not."
echo "Edit the xnat.cfg file: set xnat_version to the desired version. Replace non-compatible plugins in the /plugins directory"
read -p 'This will stop XNAT and attempt to update the xnat version. Ensure your plugins are compatible. Do you wish to continue? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi

linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)
source $install_dir/xnat.cfg
XNAT_VER=$xnat_version

#get xnat container id
LINE=$(docker ps | egrep xnat-web | cut -c1-12)
echo "$LINE"

# download XNAT
curl -L -o /xnat-data/xnat/scripts/xnat.war  https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VER}.war

#stop XNAT
docker exec -it "$LINE" /usr/local/tomcat/bin/shutdown.sh
sleep 60
#delet old XNAT, replace with new one:
docker exec -it "$LINE" rm -r /usr/local/tomcat/webapps/ROOT
docker exec -it "$LINE" unzip -o -d /usr/local/tomcat/webapps/ROOT /data/scripts/xnat.war

#delete downlaoded xnat.war file to save space
rm -f /xnat-data/xnat/scripts/xnat.war

#clean container first then save image.
docker commit "$LINE" /data/scripts/clean_image.sh
docker commit "$LINE" xnat-${XNAT_VER}

echo "Edit docker-compose.yml: replace image: xnat:latest with xnat-${XNAT_VER}"
echo "After editing docker-compose.yml, restart: sudo ./restart.sh"
echo "If there are issues, revert to the previous docker image - use the image xnat:latest and restart"







#!/usr/bin/env bash
#sudo docker exec -it `sudo docker ps -q --filter ancestor=xnat1:latest` /opt/scripts/restart_tomcat.sh
#sudo docker exec -it `sudo docker ps -q --filter ancestor=xnat2:latest` /opt/scripts/restart_tomcat.sh
linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)
if [ ! -f "$install_dir/xnat.cfg" ]
then
        echo "Error: Cannot find xnat.cfg file"
        exit 1
fi



dos2unix $install_dir/xnat.cfg
source $install_dir/xnat.cfg


XNAT=$(docker ps | egrep xnat-web | cut -c1-12)

echo "###################################"
echo "Resarting tomcat in containers - XNAT: $XNAT"
echo "###################################"
sudo docker exec -it "$XNAT"   bash -c    "/usr/local/tomcat/bin/shutdown.sh"

echo "Shutting down Tomcat. Please wait."
sleep 60
rm $xnat_home/scripts/plugins/*
cp -r $install_dir/plugins  $xnat_home/scripts/
sudo docker exec -it "$XNAT"  chmod 775 /data/scripts/restart_tomcat.sh
sudo docker exec -it "$XNAT"  bash -c '/data/scripts/restart_tomcat.sh'

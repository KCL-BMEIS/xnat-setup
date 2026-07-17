#!/usr/bin/env bash

echo "Your current XNAT must be running!"
echo "Edit the xnat.cfg file: set xnat_version to the desired version, and update any plugin versions that require upgrading to ensure compatibility."
read -p 'This will stop XNAT and attempt to update the xnat version. Ensure your plugins are compatible. Do you wish to continue? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi
current_xnat_version=$(docker ps | egrep xnat-web | cut -c13-32 | tr -d '[:space:]')
if [[ "$current_xnat_version" == *xnat* ]]; then
  echo "XNAT image detected: $current_xnat_version"
else
  echo "Error: XNAT not running? No xnat container detected: $current_xnat_version"
  exit 1
fi


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
xnat_home="$xnat_data/xnat"
postgres_path="$xnat_data/postgresql"


echo "Upgrading XNAT from $current_xnat_version to version: ${xnat_version}"
echo "#############################"
echo "Creating new docker image with updated XNAT version"
cd Linux
docker build --build-arg OLD_XNAT_VERSION="${current_xnat_version}" --build-arg XNAT_VERSION="${xnat_version}" -f Dockerfile-UpdateWar -t xnat:"${xnat_version}" .
rc=$?; if [[ $rc != 0 ]]; then echo "could not build docker image " && exit; fi


read -t 10 -p 'Have you updated plugin versions in the xnat.cfg file (default n, timeout 10s)? y/n ' cont
if [ "$cont" == "y" ]
then

    echo "#############################"
    echo "Downloading Updated Plugins"
    cd "$install_dir/Linux/"
    warning_messages="$(/bin/bash download_plugins.sh)"
    cd ..
    rm $xnat_home/scripts/plugins/*
    cp -R ./plugins/*.jar  $xnat_home/scripts/


fi


echo "--------------------------------------------------------------------------------------"
#print eny warnings about downloading plugins
echo "##############################"
echo "$warning_messages"
echo "##############################"
echo "Edit docker-compose.yml: replace image ${current_xnat_version} with xnat:${xnat_version}"
echo "After editing docker-compose.yml, restart: sudo ./restart.sh"
echo "If there are issues, revert to the previous docker image - use the previous image ${current_xnat_version} and restart"
echo "WARNING: If you updated plugins, and need to revert, change versions in xnat.cfg and rerun this script."
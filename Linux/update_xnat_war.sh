#!/usr/bin/env bash

echo "This script assumes you are using xnat:latest docker image for XNAT. Edit the Dockerfile-UpdateWar file before running if not."
echo "Edit the xnat.cfg file: set xnat_version to the desired version, and update any plugin versions that require upgrading to ensure compatibility."
read -p 'This will stop XNAT and attempt to update the xnat version. Ensure your plugins are compatible. Do you wish to continue? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi

#repo containing xnat plugins
bitbucket_repo="https://api.bitbucket.org/2.0/repositories"

newline=$'\n'
warning_messages="### Warning messages: $newline"

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

echo "Upgrading XNAT to version: ${xnat_version}"
echo "#############################"
echo "Creating new docker image with updated XNAT version"
cd Linux
docker build --build-arg XNAT_V="${xnat_version}" -f Dockerfile-UpdateWar -t xnat:"${xnat_version}" .
rc=$?; if [[ $rc != 0 ]]; then echo "could not build docker image " && exit; fi



## COPY PLUGINS
echo "#############################"
echo "Downloading Updated Plugins"
cd ..
cd plugins
if [  "$batch_launch" = true ]
then
  rm -f *batch-launc*
  wget  "${bitbucket_repo}/xnatx/xnatx-batch-launch-plugin/downloads/batch-launch-$batch_launch_version.jar"
  rc=$?;   if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download batch launch plugin rc:$rc $newline ${bitbucket_repo}/xnatx/xnatx-batch-launch-plugin/downloads/batch-launch-$batch_launch_version.jar $newline "; fi

fi
if [  "$container_service" = true ]
then
  rm -f *container-ser*
  wget "${bitbucket_repo}/xnatdev/container-service/downloads/container-service-$container_service_version-fat.jar"
  rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download container service plugin rc:$rc $newline"; fi
fi
if [  "$dqr" = true ]
then
  rm -f *dicom-query-retrieve*
  wget "${bitbucket_repo}/xnatdev/dicom-query-retrieve/downloads/dicom-query-retrieve-$dqr_version-xpl.jar"
  rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download dqr plugin rc:$rc $newline"; fi
fi
if [  "$xsync" = true ]
then
  rm -f *xsync*
  wget "${bitbucket_repo}/xnatdev/xsync/downloads/xsync-plugin-all-$xsync_version.jar"
  rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download xsync plugin rc:$rc $newline"; fi
fi
if [  "$ldap" = true ]
then
  rm -f *ldap-auth*
  wget "${bitbucket_repo}/xnatx/ldap-auth-plugin/downloads/ldap-auth-plugin-$ldap_version.jar"
  rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download ldap plugin: rc:$rc $newline"; fi
fi
if [  "$ohif_viewer" = true ]
then
  rm -f *ohif-viewer*
  wget "${bitbucket_repo}/icrimaginginformatics/ohif-viewer-xnat-plugin/downloads/ohif-viewer-$ohif_viewer_version.jar"
  rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download ohif viewer plugin: rc:$rc $newline"; fi
fi

cd ..
rm $xnat_home/scripts/plugins/*
cp -R ./plugins/  $xnat_home/scripts/


echo "--------------------------------------------------------------------------------------"
#print eny warnings about downloading plugins
echo "$warning_messages"
echo "Edit docker-compose.yml: replace image xnat:latest with xnat:${xnat_version}"
echo "After editing docker-compose.yml, restart: sudo ./restart.sh"
echo "If there are issues, revert to the previous docker image - use the image xnat:latest (or previous image if not using) and restart"
echo "WARNING: If you updated plugins, and need to revert, change versions in xnat.cfg and rerun this script."





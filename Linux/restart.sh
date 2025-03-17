#!/usr/bin/env bash
stack=$1
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
cd $install_dir


docker stack rm xnat-stack

echo "Shutting down XNAT Stack. Please wait."

## COPY PLUGINS AND WEBAPPS
#repo containing xnat plugins
bitbucket_repo="https://api.bitbucket.org/2.0/repositories"
newline=$'\n'
warning_messages="### Warning messages: $newline"
read -t 10 -p 'Have you updated plugin versions in the xnat.cfg file (default n, timeout 10s)? y/n ' cont
if [ "$cont" == "y" ]
then

      cd plugins
      if [  "$batch_launch" = true ]
      then
        echo "Updating batch launch to $batch_launch_version"
        rm -f *batch-launc*
        wget  "${bitbucket_repo}/xnatx/xnatx-batch-launch-plugin/downloads/batch-launch-$batch_launch_version.jar"
        rc=$?;   if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download batch launch plugin rc:$rc $newline ${bitbucket_repo}/xnatx/xnatx-batch-launch-plugin/downloads/batch-launch-$batch_launch_version.jar $newline "; fi

      fi
      if [  "$container_service" = true ]
      then
        rm -f *container-ser*
        echo "Updating container service to $container_service_version"
        wget "${bitbucket_repo}/xnatdev/container-service/downloads/container-service-$container_service_version-fat.jar"
        rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download container service plugin rc:$rc $newline"; fi
      fi
      if [  "$dqr" = true ]
      then
        rm -f *dicom-query-retrieve*
        echo "Updating DQR to $dqr_version"
        wget "${bitbucket_repo}/xnatdev/dicom-query-retrieve/downloads/dicom-query-retrieve-$dqr_version-xpl.jar"
        rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download dqr plugin rc:$rc $newline"; fi
      fi
      if [  "$xsync" = true ]
      then
        rm -f *xsync*
        echo "Updating XSync to $xsync_version"
        wget "${bitbucket_repo}/xnatdev/xsync/downloads/xsync-plugin-all-$xsync_version.jar"
        rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download xsync plugin rc:$rc $newline"; fi
      fi
      if [  "$ldap" = true ]
      then
        rm -f *ldap-auth*

        echo "Updating LDAP to $ldap_version"
        wget "${bitbucket_repo}/xnatx/ldap-auth-plugin/downloads/ldap-auth-plugin-$ldap_version.jar"
        rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download ldap plugin: rc:$rc $newline"; fi
      fi
      if [  "$ohif_viewer" = true ]
      then
        rm -f *ohif-viewer*
        echo "Updating OHIF Viewer to $ohif_viewer_version"
        wget "${bitbucket_repo}/icrimaginginformatics/ohif-viewer-xnat-plugin/downloads/ohif-viewer-$ohif_viewer_version.jar"
        rc=$?; if [[ $rc != 0 ]]; then warning_messages="$warning_messages warning: could not download ohif viewer plugin: rc:$rc $newline"; fi
      fi

      cd ..
      #print eny warnings about downloading plugins
      echo "$warning_messages"

fi



rm $xnat_home/scripts/plugins/*
cp -r $install_dir/plugins  $xnat_home/scripts/
sleep 30

cd $install_dir

docker stack deploy -c $install_dir/docker-compose.yml xnat-stack

sleep 15
timeout 300 tail -f $xnat_home/scripts/logs/setup.log





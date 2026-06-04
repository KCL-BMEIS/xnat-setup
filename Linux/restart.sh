#!/usr/bin/env bash
option=$1
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
xnat_home="$xnat_data/xnat"
postgres_path="$xnat_data/postgresql"


docker stack rm xnat-stack
echo "Shutting down XNAT Stack. Please wait."


if [ "$option" == "CI" ]; then
  # read -t  timeout option freezes in CI, so have to skip
  printf "\n Restarting in CI mode \n"

else
  read -t 10 -p 'Have you updated plugin versions in the xnat.cfg file (default n, timeout 10s)? y/n ' cont
  if [ "$cont" == "y" ]
  then
      cd "$install_dir/Linux/"
      /bin/bash download_plugins.sh
  else
    echo "Not Updating Plugins"
  fi
fi
echo "Pausing for 30s"
cd $install_dir
rm $xnat_home/scripts/plugins/*
cp  $install_dir/plugins/*  $xnat_home/scripts/plugins/
sleep 30


echo "Redeploying XNAT"
docker stack deploy -c $install_dir/docker-compose.yml xnat-stack

sleep 30

echo "############ Updating Postgresql Settings from xnat.cfg..."
cd postgres
  /bin/bash set_postgres_db.sh
  rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ..


timeout 300 tail -f $xnat_home/scripts/logs/setup.log





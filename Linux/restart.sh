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
rm $xnat_home/scripts/plugins/*
cp -r $install_dir/plugins  $xnat_home/scripts/
sleep 30

cd $install_dir

docker stack deploy -c $install_dir/docker-compose.yml xnat-stack

sleep 15
timeout 300 tail -f $xnat_home/scripts/logs/setup.log





#!/usr/bin/env bash

read -p 'This will delete ALL docker images and containers, data, databases and current configurations. Do you wish to Continue? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi


linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)
source $install_dir/xnat.cfg
xnat_home="$xnat_data/xnat"
postgres_path="$xnat_data/postgresql"
import_data_folder="$xnat_data/import_data"

docker stack rm xnat-stack


if [ -d "$import_data_folder" ]
then
     rm -r $import_data_folder
fi

if [ -d "$xnat_home" ]
then
     rm -r $xnat_home
fi

if [ -d "$postgres_path" ]
then
     rm -r $postgres_path
fi


if [ -d "./xnat_proxy" ]
then
     rm -r ./xnat_proxy
fi

sleep 30
cd Linux
./build.sh


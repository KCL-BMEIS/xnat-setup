#!/usr/bin/env bash
read -p 'This will delete ALL docker images and containers. Do you wish to Continue? y/n ' cont
if [ "$cont" != "y" ]
then
  exit
fi


linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)
cd $install_dir
source $install_dir/xnat.cfg
xnat_home="$xnat_data/xnat"
postgres_path="$xnat_data/postgresql"
import_data_folder="$xnat_data/import_data"


docker stack rm xnat-stack
sleep 100

docker system prune
docker images purge

docker secret rm pgpass

docker rm $(docker ps -qa --no-trunc --filter "status=exited")
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -a -q)

#delet
test=$1
if [ "$test" != "test" ]
then
    rm -rf $xnat_data
fi
cd Linux

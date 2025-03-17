#!/usr/bin/env bash


#Check dockerhib for suitable tag
#https://hub.docker.com/_/nginx?tab=tags&page=1
PG_VERSION="postgres:16"
NGINX_VERSION="nginx:stable-alpine"

# need to set timezone in docker images to match
timezone=$(cat /etc/timezone)
echo "Timezone: $timezone"



linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)

echo "#######Pulling new docker images..."
docker pull "$PG_VERSION"
docker pull "$NGINX_VERSION"

echo "#########Building new docker images..."
cd postgres
docker build  --build-arg TIMEZONE=${timezone} -f Dockerfile -t postgres-xnat .
cd ../nginx
docker build -t nginx-xnat .
cd ../Linux

./restart.sh
#apt update and upgrade run in xnat-web when restarted.


cd ..

sleep 100
echo "######Changing Postgresql Settings..."
cd postgres
  /bin/bash set_postgres_db.sh
  rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ..

XNAT1=$(docker ps | egrep xnat-web | cut -c1-12)
docker exec  "$XNAT1"   apt-get -y update
docker exec  "$XNAT1"   apt-get -y upgrade
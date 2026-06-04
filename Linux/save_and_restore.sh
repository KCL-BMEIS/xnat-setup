#!/usr/bin/env bash
linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)
source $install_dir/xnat.cfg
xnat_home="$xnat_data/xnat"
postgres_path="$xnat_data/postgresql"


#INSTRUCTION for building on one server and transferring to another:
# Setup a PC with public access following the instructions on the wiki.
# Fill in the xnat.cfg file, but ensure you use the url of the intended host.
# In order to work with Linux, the postgresql folder cannot be mounted - before starting you must edit some files. Only do this on the old server.
# docker-compose.yml:
#         delete lines:
#              #LINX- @POSTGRES_PATH@/postgres-data:/var/lib/postgresql/data
# After running ./build.sh use this script:
#    ./save_and_restore.sh save
# This will create a backup directory.
# Copy the backup directory to /path/to/xnat-setup/Linux on your new server. Copy the xnat.cfg over.
# Run:
#    ./save_and_restore.sh restore




restore=$1


if [ "$restore" = "restore" ]
then
	echo "Restoring images and storage from ./backup"
	if [ ! -d "./backup" ]
    then
        echo "There is no backup subfolder in the current directory."
        exit 1
	fi
	docker stack rm xnat-stack
	cp ./backup/xnat.cfg ./
	cp ./backup/docker-compose.yml ./
	cd backup
  docker load -i nginx-xnat.tar.gz
  docker load -i postgres-xnat.tar.gz
  docker load -i xnat.tar.gz
  cd ..
  mkdir /xnat-data
  rm -rf $xnat_home
  mkdir $xnat_home
  tar -C $xnat_home -xzf  ./backup/xnat_home.tar.gz

  rm -rf $postgres_path
  mkdir $postgres_path
  tar -C $postgres_path -xzf  ./backup/postgres_path.tar.gz


	docker stack deploy -c docker-compose.yml xnat-stack
	cd Linux
	echo "If XNAT does not start, check that the correct xnat image is being used in docker-compose.yml - xnat:latest"
    

elif [[ "$restore" = "save" ]]; then
	#statements
	XNAT=$(docker ps | egrep xnat-web | cut -c1-12)

	echo "Saving images and storage to ./backup , XNAT: $XNAT"
	echo "Backing up pg database"
	docker exec  "$XNAT" chmod 775 /data/scripts/clean_image.sh

	docker exec  "$XNAT" /data/scripts/cronjobs/pg_backup.sh

	echo "Minimise docker image"
	docker exec "$XNAT" /data/scripts/clean_image.sh

	echo "Backing up containers"
	docker commit "$XNAT"  xnat
  PG=$(docker ps | egrep xnat-db | cut -c1-12)
  docker commit "$PG"  postgres-xnat
	NGINX=$(docker ps | egrep nginx | cut -c1-12)
	docker commit "$NGINX"  nginx-xnat

	echo "Stopping XNAT and saving to /backup directory"
	docker stack rm xnat-stack
	rm -rf backup
	mkdir backup
	cp xnat.cfg ./backup
	cp docker-compose.yml ./backup
	cd backup
	docker image save  nginx-xnat > nginx-xnat.tar
	gzip nginx-xnat.tar
	docker image save postgres-xnat > postgres-xnat.tar
	gzip postgres-xnat.tar
  docker image save xnat > xnat.tar
  gzip xnat.tar

  cd ..
  tar -zcvf ./backup/xnat_home.tar.gz -C $xnat_home .
  tar -zcvf ./backup/postgres_path.tar.gz -C $postgres_path .

  #restart XNAT
  cd Linux
  ./restart.sh

else
    echo "missing paramter 'save' or 'restore'"

fi

#!/usr/bin/env bash
linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)
source $install_dir/xnat.cfg

#in order to save images and files, then restore on another ocmputer.
# in xnat.cfg, use the ip address of the intended PC

#INSTRUCTIONS:
#Setup a PC with public access follwoing the instrucitons int he wiki. 
# Fill int he xnat.cfg file, but ensure you use the IP address of the intended host.
#After runing ./build.sh use this script:
#    ./save_and_restore.sh save
#This will create a backup directroy. 
# Copy he backup to ./uploader/ folder of the new computer and run:
#    ./save_and_restore.sh restore

## In order to work with Linux, the postgresql fodler cannot be mounted - before starting you must edit spome files:

# docker-compose-template:
#         line 27, 71 - remove #WIN#, so /pg_backup will be mounted:
#              ./volume/postgres-data1:/pg_backup
#              ./volume/postgres-data2:/pg_backup
#         delete lines 95,50:
#              LINX- ./volume/postgres-data1:/var/lib/postgresql/data
#              LINX- ./volume/postgres-data2:/var/lib/postgresql/data
# ./xnat/templates/cronjoobs.txt:
#        delete #WIN# - this way, the postgresql will backup to the new mounted folder


xnat_home_out="/xnat-data/xnat"
postgres_path_out="/xnat-data/postgresql"


restore=$1


if [ "$restore" = "restore" ]
then
	echo "Restoring images and storage from ./backup"
	if [ ! -d "./backup" ]
    then
        echo "There is no backup subfolder in the crrent directory."
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
  rm -rf $xnat_home_out
  mkdir $xnat_home_out
  tar -C $xnat_home_out -xzf  ./backup/xnat_home.tar.gz

  rm -rf $postgres_path_out
  mkdir $postgres_path_out
  tar -C $postgres_path_out -xzf  ./backup/postgres_path.tar.gz


	docker stack deploy -c docker-compose.yml xnat-stack
	cd Linux
    



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

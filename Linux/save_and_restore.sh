#!/usr/bin/env bash
linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)
source $install_dir/xnat.cfg
xnat_home="$xnat_data/xnat"
postgres_path="$xnat_data/postgresql"
import_data_folder="$xnat_data/import_data"


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
	echo "##### Restoring images and storage from ./backup"
	if [ ! -d "./backup" ]
    then
        echo "There is no backup subfolder in the current directory."
        exit 1
	fi

	 	read -p  "If you already have XNAT setup, this will replace your postgresql database, and most of your mount points (archive optional.  Continue ? y/n " cont
      if [ "$cont" != "y" ]; then
          exit
      fi



	docker stack rm xnat-stack
	cp ./backup/xnat.cfg ./
	cp ./backup/docker-compose.yml ./
	cd backup
	echo "#### Loading docker images"
  docker load -i nginx-xnat.tar.gz
  docker load -i postgres-xnat.tar.gz
  docker load -i xnat.tar.gz
  cd ..
  echo "#### Images restored"
 echo "-----------------------------------------"
  if  [ ! -d "$import_data_folder" ]; then
      mkdir -p $import_data_folder
  fi

  echo "#### Restoring $postgres_path"
  if  [ -d "$postgres_path" ]; then
      rm -rf $postgres_path
  fi
  mkdir $postgres_path
  tar -C $postgres_path -xzf  ./backup/postgres_path.tar.gz

  echo "#### Restoring $xnat_home"
 #unzip and move, check if archive in zip
 mkdir -p /tmp/xnat-home
  tar -C /tmp/xnat-home/ -xzf  ./backup/xnat_home.tar.gz

  if  [ ! -d "$xnat_home" ]; then
    mkdir -p $xnat_home
  fi

  xnat_dirs=( 'build' 'inbox' 'tomcat_logs' 'nginx_logs' 'certificates' 'scripts')
  for xnat_dir in "${xnat_dirs[@]}"
  do
      #echo "${xnat_home}/${xnat_dir}"
      if [  -d "${xnat_home}/${xnat_dir}" ]; then
          echo "Replacing ${xnat_dir} directory"
          rm -rf "${xnat_home}/${xnat_dir}"
      fi
      if [  -d "/tmp/xnat-home/${xnat_dir}" ]; then
            echo "Moving ${xnat_dir} mv  /tmp/xnat-home/${xnat_dir} ${xnat_home}/${xnat_dir}"
            mv  /tmp/xnat-home/${xnat_dir} "${xnat_home}/${xnat_dir}"

      fi
  done

  #mkdir -p $xnat_home/cache
  mkdir -p $xnat_home/build
  mkdir -p $xnat_home/inbox


  if  [ -d /tmp/xnat-home/archive ] && [  -d "${xnat_home}/archive" ]; then

      read -p  "${xnat_home}/archive already exists. Overwrite? y/n " cont
      if [ "$cont" != "y" ]
      then
        echo "Not overwriting archive, exiting"
        exit
      else
        echo "replacing archive mv  /tmp/xnat-home/archive ${xnat_home}/archive"
        rm -rf "${xnat_home}/archive"
        mv  /tmp/xnat-home/archive "${xnat_home}/archive"
      fi
  elif [ -d /tmp/xnat-home/archive ]; then
    echo "Moving archive mv  /tmp/xnat-home/archive ${xnat_home}/archive"
    mv  /tmp/xnat-home/archive "${xnat_home}/archive"
  elif [ ! -d "${xnat_home}/archive" ];then
    echo "No backup archive or existing archive found. Creating empty archive..."
    mkdir -p "${xnat_home}/archive"
  else
    echo "No archive backup found, keeping existing"
  fi



  echo "Change dcoker-compose.yml. Set images to xnat:backup,postgres-xnat:backup ,nginx-xnat:backup and restart XNAT"
	#docker stack deploy -c docker-compose.yml xnat-stack
	cd Linux

    

elif [[ "$restore" = "save" ]]; then
	#statements

	XNAT=$(docker ps | egrep xnat-web | cut -c1-12)
	if [ "${#XNAT}" -lt 4 ]
	then
	  echo "No XNAT container found!!! Is XNAT running? "
	  exit
	fi

 echo "-----------------------------------------"
	echo "######## Saving images and storage to ./backup , XNAT: $XNAT"
	echo "#### Backing up pg database"
	docker exec  "$XNAT" chmod 775 /data/scripts/clean_image.sh

	docker exec  "$XNAT" /data/scripts/cronjobs/pg_backup.sh

 echo "-----------------------------------------"
	echo "######## Minimise docker image"
	docker exec "$XNAT" /data/scripts/clean_image.sh

 echo "-----------------------------------------"
	echo "######## Backing up containers"
	docker commit "$XNAT"  xnat:backup
  PG=$(docker ps | egrep xnat-db | cut -c1-12)
  docker commit "$PG"  postgres-xnat:backup
	NGINX=$(docker ps | egrep nginx | cut -c1-12)
	docker commit "$NGINX"  nginx-xnat:backup

 echo "-----------------------------------------"
	echo "######## Stopping XNAT and saving images to /backup directory"
	docker stack rm xnat-stack
	rm -rf backup
	mkdir backup
	cp xnat.cfg ./backup
	cp docker-compose.yml ./backup
	cd backup
	docker image save  nginx-xnat:backup > nginx-xnat.tar
	gzip nginx-xnat.tar
	docker image save postgres-xnat:backup > postgres-xnat.tar
	gzip postgres-xnat.tar
  docker image save xnat:backup > xnat.tar
  gzip xnat.tar

  cd ..
 echo "-----------------------------------------"
	echo "######## Backing up mounted directories"

    read -p  "Tar archiving /xnat-data/xnat - do you wish to backup the entire archive too? (if large, you will want to skip this) ? y/n " cont
      if [ "$cont" != "y" ]
    then
      tar -zcf ./backup/xnat_home.tar.gz --exclude="./archive"  --exclude="./inbox"  --exclude="./build" --exclude="./cache"  -C $xnat_home .
    else
      tar -zcf ./backup/xnat_home.tar.gz  --exclude="./inbox" --exclude="./build" --exclude="./cache"  -C $xnat_home .
    fi



# https://www.postgresql.org/docs/current/continuous-archiving.html
# omit pg_wal/ , pgsql_tmp, contents of pg_dynshmem/, pg_notify/, pg_serial/, pg_snapshots/, pg_stat_tmp/, and pg_subtrans/
# pg_internal.init
cp -r $postgres_path ./backup
cd backup
rm -rf ./postgresql/postgres-data/pg_wal
rm -rf ./postgresql/postgres-data/pg_dynshmem/*
rm -rf ./postgresql/postgres-data/pg_snapshots/*
rm -rf ./postgresql/postgres-data/pg_stat_tmp/*
rm -rf ./postgresql/postgres-data/pg_subtrans/*
tar -zcf ./postgres_path.tar.gz -C $postgres_path .

  #restart XNAT
   echo "-----------------------------------------"
   echo "###### Restarting XNAT"
  cd ../Linux
  ./restart.sh

else
    echo "missing paramter 'save' or 'restore'"

fi

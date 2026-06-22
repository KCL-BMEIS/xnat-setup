#!/usr/bin/env bash
in_command=$1
CI=$2

# need to set timezone in docker images to match
timezone=$(cat /etc/timezone)
echo "Timezone: $timezone"

#static postgresql user
psql_user="xnat"

linux_dir=$(dirname "$0")
cd "$linux_dir"
cd ..
install_dir=$(pwd)
if [ ! -f "$install_dir/Linux/build.sh" ]
then
        echo "Error: You must run the build.sh script from the same directory as the script."
        exit 1
fi

if [ ! -f "$install_dir/xnat.cfg" ]
then
        echo "Error: Cannot find xnat.cfg file"
        exit 1
fi

# remove spaces, convert to unix format and read configuration file
sed -i "s/ //g"  "$install_dir/xnat.cfg"
dos2unix "$install_dir/xnat.cfg"
source "$install_dir/xnat.cfg"
xnat_home="$xnat_data/xnat"
postgres_path="$xnat_data/postgresql"
import_data_folder="$xnat_data/import_data"

#used to be seperate, now uses same as xnat_home

if [ "${in_command,,}" == "upgrade"  ] ; then
    read -p  "Upgrading XNAT to $xnat_version. Ensure everything is backed up. Do you wish to Continue? y/n " cont
    if [ "$cont" != "y" ]  && [ "$CI" != "CI" ]
    then
      exit
    fi
    ###get psql password
    LINE=$(docker ps | grep -E xnat-web | cut -c1-12)
    if [ ${#LINE} -le 4 ]
    then
        echo "Error: Is XNAT running?  No XNAT container found. "
        exit 1
    fi

    docker exec -it "$LINE" cp /data/xnat/home/config/xnat-conf.properties /data/scripts
    psql_pwd=$(sed -n 's/^datasource.password=//p'  "$xnat_home/scripts/xnat-conf.properties")
    if [ ${#psql_pwd} -le 4 ]
    then
        echo "Error: Could not find postgresql password in xnat docker container - Running?"
        exit 1
    fi

    # remove properties file once extracted pwd
    rm -f "$xnat_home/scripts/xnat-conf.properties"

    # remove existing plugins if upgrading
    rm -f "$xnat_home/scripts/plugins/*.jar"

elif [  "${in_command,,}"  == "ci" ]; then
   echo "Building XNAT - CI"
else
  read -p  "Building XNAT. This will build the docker containers and interrupt existing containers. Do you wish to Continue? y/n " cont
      if [ "$cont" != "y" ]
    then
      exit
    fi
fi


echo "### CHECKING to see if shared folders exist   ###"
if [ -d "$xnat_home" ] && [  "${in_command,,}"  != "upgrade" ]
then
    echo "Archive path already exists. Use restart_and_clean.sh or restart.sh"
    exit 1
fi

echo "### CHECKING XNAT.CFG FILE FOR ERRORS - $xnat_host   ###"

if [  "$ssl" = true ] && [[ "$xnat_host" != "https://"*  ]]
then
        echo "Error: URL malformed, SSL selected but URL does not start with https://"
        exit 1
fi
if [  "$ssl" = false ] && [[ "$xnat_host" != "http://"* ]]
then
    echo "Error: URL malformed, does not start with http://"
    exit 1
fi

if [ ${#xnat_home} -le 2 ]
then
    echo "Error: Check xnat.cfg - xnat_home too short - path: $xnat_home "
    exit 1
fi
if [ ${#import_data_folder} -le 2 ]
then
    echo "Error: Check xnat.cfg - import_data_folder too short - path: $import_data_folder"
    exit 1
fi



if [ "$xnat_admin_user" = "admin" ]
  then
      echo "Error: Check xnat.cfg - xnat_admin_user cannot be admin"
      exit 1
fi


if [ ${#xnat_admin_user} -le 2 ]
then
    echo "Error: Check xnat.cfg - xnat_admin_user too short"
    exit 1
fi


if [ ${#psql_pwd} -le 4 ] && [  "${in_command,,}"  != "upgrade" ]
then
    echo "Error: Check xnat.cfg - psql_pwd too short $psql_pwd"
    exit 1
fi

if [ ${#site_name} -le 2 ]
then
    echo "Error: Check xnat.cfg - site_name too short"
    exit 1
fi

if [ ${#xnat_version} -le 2 ]
then
    echo "Error: Check xnat.cfg - xnat_version is too short/missing"
    exit 1
fi

if [ ${#xnat_version} -le 2 ]
then
    echo "Error: Check xnat.cfg - xnat_version is too short/missing"
    exit 1
fi
if [ "$ohif_viewer" != "true" ] && [ "$ohif_viewer"  != "false" ]
then
    echo "Error: Check xnat.cfg - check that plugins (ohif) are selected true/false: $ohif_viewer"
    exit 1
fi
if [ "$container_service"  != "true"  ] && [ "$container_service" != "false" ]
then
    echo "Error: Check xnat.cfg - check that plugins (container service) are selected true/false: $container_service"
    exit 1
fi


if [ "$ssl" = true ]
then
    if [ ${#ssl_key_file} -le 2 ]
    then
        echo "Error: Check xnat.cfg - ssl key file missing "
        exit 1
    fi
        if [ ${#ssl_crt_file} -le 2 ]
    then
        echo "Error: Check xnat.cfg - ssl crt file missing "
        exit 1
    fi
    if [ ${#ssl_trust_file} -le 2 ]
    then
        echo "Error: Check xnat.cfg - ssl trust file missing "
        exit 1
    fi
    if [[ "$ssl_key_file" = *"/"* ]]
    then
        echo "Error: Check xnat.cfg - ssl key file contains a file seperator - only include the filename"
        exit 1
    fi

    if [[ "$ssl_crt_file" = *"/"* ]]
    then
        echo "Error: Check xnat.cfg - ssl crt file contains a file seperator - only include the filename"
        exit 1
    fi

    if [[ "$ssl_trust_file" = *"/"* ]]
    then
        echo "Error: Check xnat.cfg - ssl trust file contains a file seperator - only include the filename"
        exit 1
    fi

fi


stacks=$(docker stack ls)
if [[ $stacks = *"xnat-stack"* ]]; then
    echo "### xnat already running.... stopping current service and rebuilding###"
	docker stack rm xnat-stack
	sleep 60
fi
docker swarm leave

echo "### Installing XNAT - $site_name   ###"
echo "### Using config file xnat.cfg      ###"
echo "# URL:  $xnat_host            ###"
echo "# XNAT Name: $site_name      ###"
echo "# xnat home path:  $xnat_home            ###"
echo "# admin user:  $xnat_admin_user            ###"
echo "# admin email:  $xnat_admin_email            ###"



if [  "${in_command,,}"  != "upgrade" ]; then
    mkdir -p "$xnat_home/archive/"
    mkdir -p "$postgres_path/postgres-data/"
    mkdir -p "$xnat_home/certificates/"
    mkdir -p "$xnat_home/tomcat_logs/"
    mkdir -p "$xnat_home/nginx_logs/"
    mkdir -p "$xnat_home/build/"
    mkdir -p "$xnat_home/inbox/"
    mkdir -p "$import_data_folder"
    chmod 777 "$import_data_folder"

    mkdir -p "$xnat_home/scripts/logs/"
    mkdir -p "$xnat_home/scripts/access_logs/"
    mkdir -p "$xnat_home/scripts/plugins"
fi

if [ ! -d "$xnat_home/inbox" ]
then
  # some old installs did not have, so required when upgrading
  mkdir -p "$xnat_home/inbox/"
fi

if [ -d "$xnat_home/archive" ]
then
    echo "Success: xnat archive $xnat_home/archive created"
else
    echo "Error: No archive path created"
    exit 1
fi
if [ -d "$import_data_folder" ]
then
    echo "Success: import data folder $import_data_folder created"
else
    echo "Error: No import data folder exists"
    exit 1
fi


### need to edit setup_xnat.sh...
cp xnat.cfg ./xnat/xnat.cfg
cp ./xnat/templates/prefs-init.ini-template ./xnat/conf1/prefs-init.ini
cp ./xnat/templates/site-config-template.json ./xnat/conf1/siteConfig.txt
cp ./xnat/templates/xnat-conf.properties-template ./xnat/conf1/xnat-conf.properties


# SET TOMCAT MEMORY
# Java memory can be more than Xmx
# JVM memory = Heap memory+ Metaspace + CodeCache + (ThreadStackSize * Number of Threads) + DirectByteBuffers + Jvm-native
# -XX:MetaspaceSize
# -XX:MaxMetaspaceSize
# -OmitStackTraceInFastThrow - disables optimisation....
# for java 8
# -XX:+UseG1GC - default on some system (Xmx > 6gb), attempts high throuput and short pauses
# -XX:+UseParallelGC - use multi cores - NOT G1GC - do not use
# -XX:ParallelGCThreads=6 \\  - number of cores....
# # -XX:MaxGCPauseMillis=200 - not that important for XNAT, if GC takes longer...
# -XX:GCTimeRatio, like above, memory more important than time down
# -XX:+UseStringDeduplication - reduces memory by 10% by finding duplicates
# -Djava.awt.headless=true \\ - ie, no java windows etc, good for server side apps

#-XX:ConcGCThreads=3 \\
#-XX:+ParallelRefProcEnabled \\
#-XX:+UnlockExperimentalVMOptions \\
#-XX:+DisableExplicitGC \\

echo "export CATALINA_OPTS=\"\${CATALINA_OPTS} -Xms${Xms} -Xmx${Xmx} \"" > ./xnat/conf1/setenv.sh

echo "export CATALINA_OPTS=\"\${CATALINA_OPTS} -Dxnat.home=/data/xnat/home  -XX:+UseG1GC   -Djava.awt.headless=true -XX:+ParallelRefProcEnabled -XX:ParallelGCThreads=${cpu_cores}   -XX:+UseStringDeduplication  \"" >> ./xnat/conf1/setenv.sh

# mentions when startig tomcat: EXPERIMENTAL - only works if experimental unlocked
# echo "export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+UnlockExperimentalVMOptions. -XX:+EnableJVMCI \"" > ./xnat/conf1/setenv.sh

### in Linux, only CATALINA important as runs first
echo "export JAVA_OPTS=\"\${JAVA_OPTS} -Xms${Xms} -Xmx${Xmx} \"" >> ./xnat/conf1/setenv.sh



#sed doesn't like underscores?
URL=$xnat_host
#sed -i -e '/@SIF@/{r ./xnat/SeriesImportFilter.txt' -e 'd}'  ./xnat/conf2/siteConfig.txt ./xnat/conf1/siteConfig.txt
sed -i "s/@XNAT_ADMIN_USER@/$xnat_admin_user/g"  ./xnat/conf1/prefs-init.ini ./xnat/conf1/siteConfig.txt
sed -i "s#@SITEURL@#$URL#g"     ./xnat/conf1/prefs-init.ini ./xnat/conf1/siteConfig.txt
sed -i "s#@PIPELINE_URL@#$URL#g" ./xnat/conf1/siteConfig.txt
sed -i "s#@SITEURL@#$URL#g" ./xnat/conf1/siteConfig.txt
sed -i "s/@ADMIN_EMAIL@/$xnat_admin_email/g" ./xnat/conf1/prefs-init.ini ./xnat/conf1/siteConfig.txt
sed -i "s/@PROJECT@/$site_name/g"  ./xnat/conf1/siteConfig.txt
sed -i "s/@PG_USR@/$psql_user/g"  ./xnat/conf1/xnat-conf.properties
sed -i "s/@PG_PWD@/$psql_pwd/g"  ./xnat/conf1/xnat-conf.properties
sed -i  "s/@SITE@/$site_name/g"    ./xnat/conf1/prefs-init.ini ./xnat/conf1/siteConfig.txt



# NGINX ssl config
NGINX_CONF='./nginx/xnat.conf'
if [ "$ssl" = true ]
then
    echo "Nginx configured for https, secure site"
    cp ./nginx/xnat_ssl.conf ./nginx/xnat.conf
else
    echo "# Nginx configured for http, no ssl configuration"
    cp ./nginx/xnat_nonssl.conf ./nginx/xnat.conf
fi
nginx_host="${xnat_host/http*:\/\//}"
echo "## nginx host: $nginx_host"
sed -i  "s#@SERVER_NAME@#$nginx_host#g"   "$NGINX_CONF"
sed -i  "s/@CRT@/$ssl_crt_file/g"   "$NGINX_CONF"
sed -i  "s/@KEY@/$ssl_key_file/g"  "$NGINX_CONF"
sed -i  "s/@PEM@/$ssl_dhparam_file/g"  "$NGINX_CONF"
sed -i  "s/@TRUST@/$ssl_trust_file/g"  "$NGINX_CONF"


if [  "${in_command,,}"  != "upgrade" ]
then
      # set docker subnet
      if [ ${#docker_subnet} -ge 6 ]
      then
        docker network create --driver overlay --subnet $docker_subnet  xnat-stack-net
        sed -i "s/#networks:/networks:/g"   "$DOCKER_FILE"
        sed -i "s/#xnat-net:/xnat-net:/g"   "$DOCKER_FILE"
        sed -i "s/#- xnat-net/- xnat-net/g"   "$DOCKER_FILE"
         sed -i "s/#name: xnat-stack-net/name: xnat-stack-net/g"   "$DOCKER_FILE"
         sed -i "s/#external: true/external: true/g"   "$DOCKER_FILE"
      fi

        if [  "$ssl" = true  ]
        then
          # skip if upgrading s already in place
            cp ./certs/* $xnat_home/certificates/
        fi


      # Create secrets....
      #POSTGRESQL
      #echo "$psql_pwd" > pgapss
      if [[ $(docker secret ls) =~ "pgpass " ]]; then
        echo " Found pgpass in docker secrets - replacing "
         docker secret rm pgpass
         sleep 20
      fi
      echo "$psql_pwd" | docker secret create pgpass -
      #?  create complex password? openssl rand -base64 20 | docker secret create pgpass_password -
      #NGINX - need for key
fi

DOCKER_FILE='docker-compose.yml'
cp docker-compose-stack.yml docker-compose.yml

sed -i  "s/#LINX//g"   "$DOCKER_FILE"
sed -i  "s#@ARCHIVE_PATH@#$xnat_home#g"   "$DOCKER_FILE"
sed -i  "s#@PWD@#$install_dir#g"   "$DOCKER_FILE"
sed -i  "s#@XNAT_HOME@#$xnat_home#g"   "$DOCKER_FILE"
sed -i  "s#@POSTGRES_PATH@#$postgres_path#g"   "$DOCKER_FILE"
sed -i  "s#@IMPORT_DATA_FOLDER@#$import_data_folder#g"   "$DOCKER_FILE"
sed -i "s/@PG_USER@/$psql_user/g"   "$DOCKER_FILE"


#### SET PROXY
#maybe copy entire directory and run - xnat_proxy
url_name=${URL:7}
echo "$url_name"
if [ "$ssl" = true ]
then
  url_name=${URL:8}
  echo "$url_name"
fi



if [ "$use_proxy" == true ]
then
    echo "######### Using proxy $proxy_url:$proxy_port"
    #JAVA_PROXY=' -Dhttp.proxyHost=$proxy_url  -Dhttp.proxyPort=$proxy_port -Dhttps.proxyHost=$proxy_url  -Dhttps.proxyPort=$proxy_port   -Dhttp.nonProxyHosts=\"localhost|127.0.0.1|xnat-web|xnat-web2|$nginx_host\" '
    JAVA_PROXY=" -Dhttp.proxyHost=$proxy_url  -Dhttp.proxyPort=$proxy_port -Dhttps.proxyHost=$proxy_url  -Dhttps.proxyPort=$proxy_port   -Dhttp.nonProxyHosts=\\\"localhost|$url_name|127.0.0.1|xnat-web\\\" "
    
    rm -rf  ./xnat_proxy
    cp -R ./xnat ./xnat_proxy
    sed -i  "s\#ENV \ENV \g"   ./xnat_proxy/dockerfile
    sed -i "s#@PROXYURL@#$proxy_url#g"   ./xnat_proxy/dockerfile
    sed -i "s#@PROXYPORT@#$proxy_port#g"   ./xnat_proxy/dockerfile
    sed -i  "s\@JAVA_PROXY@\ $JAVA_PROXY \g"   ./xnat_proxy/dockerfile
    sed -i  "s\#RUN su - \RUN su -  \g"   ./xnat_proxy/dockerfile
     sed -i "s#@URLNAME@#$url_name#g"   ./xnat_proxy/dockerfile

    
    # bash rpofile
    echo "# Using proxy - changing bash_profile"
    echo "export HTTPS_PROXY=\"$proxy_url:$proxy_port\"" >>   ./xnat_proxy/bash_profile
    echo "export https_proxy=\"$proxy_url:$proxy_port\"" >>   ./xnat_proxy/bash_profile
    echo "export ftp_proxy=\"$proxy_url:$proxy_port\"" >>   ./xnat_proxy/bash_profile
    echo "export FTP_PROXY=\"$proxy_url:$proxy_port\"" >>   ./xnat_proxy/bash_profile
    
    ## NO PROXY - nginx_host defeined earlier, it's xnat_host with http/s stripped
    echo "export no_proxy=\"localhost,$url_name,127.0.0.1,xnat-web\"" >>   ./xnat_proxy/bash_profile
    echo "export NO_PROXY=\"localhost,$url_name,127.0.0.1,xnat-web\"" >>   ./xnat_proxy/bash_profile


    echo "export JAVA_OPTS=\"\${JAVA_OPTS}  $JAVA_PROXY \"" >>   ./xnat_proxy/conf1/setenv.sh
    # should be just java_opts, as that is default
    echo "export CATALINA_OPTS=\"\${CATALINA_OPTS}  $JAVA_PROXY \"" >>   ./xnat_proxy/conf1/setenv.sh
    
   cd xnat_proxy
else
   cd xnat
fi


# DOCKER_BUILDKIT=1  ? makes faster
echo "############### Building Docker Images, XNAT version: $xnat_version   timezone: $timezone"

docker build --build-arg XNAT_VERSION=${xnat_version}  --build-arg TIMEZONE=${timezone}  -t xnat:"${xnat_version}"  .
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ..
# set version of xnat image in docker-compose
sed -i  "s|image: xnat:latest|image: xnat:${xnat_version}|g"  ./docker-compose.yml

cd nginx
docker build   --build-arg TIMEZONE=${timezone} -t nginx-xnat .
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ..
cd postgres
if [ "$use_pg_alpine" == true ]
then
  echo "## us_pg_alpine set to true: Using postresql alpine image"
  docker build  --build-arg TIMEZONE=${timezone} -f dockerfile-alpine -t postgres-xnat .
else
  docker build  --build-arg TIMEZONE=${timezone} -t postgres-xnat .
fi

rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ..

echo "completed build - downloading plugins and starting docker"
# umm, skip if upgrading?
cp -r ./scripts/* $xnat_home/scripts/
cd Linux
warning_messages="$(/bin/bash download_plugins.sh)"
cp  ../plugins/*.jar  "$xnat_home/scripts/plugins"
cd ..

echo "############ Ignore error if node already part of swarm...."
docker swarm init

echo "############ Deploying XNAT Docker Stack..."
docker stack deploy -c docker-compose.yml xnat-stack
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

sleep 10
#COnfigure postgresql settings
echo "############ Changing Postgresql Settings..."
cd postgres
  /bin/bash set_postgres_db.sh
  rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ..

#protect certificates
chmod -R 660 "$xnat_home/certificates/"


# print warning messages
echo "${warning_messages}"


if [  "${in_command,,}"  != "test" ]
then
    echo "###### RUNNING TESTS #######################"
    echo "###### PLEASE BE PATIENT, THIS WILL TAKE TIME TO APPEAR#######"

    sleep 30
    images=$(docker image ls)
    containers=$(docker ps)

    running=True
    if    [[ $images != *"nginx"* ]]; then
     echo "Nginx docker image not built. Check settings and logs. "
     running=False
    fi
    if    [[ $images != *"postgres"* ]]; then
     echo "Postgresql docker image not present. Check settings and logs. "
     running=False
    fi
     if   [[ $images != *"xnat"* ]]; then
     echo "Xnat docker image not present. Check settings and logs. "
     running=False
    fi
      if  [[ $containers != *"nginx"* ]]; then
     echo "Nginx container not running. Check settings and logs. "
     running=False
    fi
    if   [[ $containers != *"xnat-db"* ]]; then
     echo "Postgresql docker container not running. Check settings and logs. "
     running=False
    fi
    if   [[ $containers != *"xnat-web"* ]]; then
     echo "XNAT container not running. Check. Check settings and logs. "
     running=False
    fi
    if [ $running == False ]; then
      echo "Errors reported. Stopping."
      exit 0
    else
       echo "All docker container images built and containers running"
    fi




	  sed -i 's/_pwd=.*/_pwd=/g' xnat.cfg ./xnat/xnat.cfg
    sed -i 's/_pwd_research=.*/_pwd_research=/g' xnat.cfg ./xnat/xnat.cfg
    rm ./xnat/conf1/*.properties
    rm ./xnat/conf1/*.txt
    rm ./xnat/conf1/*.ini
    rm ./xnat/conf1/setenv.sh

    sleep 60

    cd Linux
    timeout 600 tail -f "$xnat_home/scripts/logs/setup.log"

fi








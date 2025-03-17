#!/usr/bin/env bash

if [ "$1" == "nginx" ]
then
    LINE=$(docker ps | egrep xnat-nginx | cut -c1-12)
    echo "Logging into nginx container: $LINE"
    docker exec -it "$LINE" /bin/sh
elif [ "$1" == "pg" ]
then
    LINE=$(docker ps | egrep xnat-db | cut -c1-12)
    echo "Logging into postgresql container: $LINE"
    docker exec -it "$LINE" /bin/sh
else
    LINE=$(docker ps | egrep xnat-web | cut -c1-12)
    echo "Logging into tomcat container: $LINE"
    docker exec -it "$LINE" /bin/bash
fi



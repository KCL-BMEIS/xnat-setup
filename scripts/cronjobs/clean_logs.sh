#!/bin/bash
find ${CATALINA_HOME}/temp/ -type f -mtime +20 -delete
cp -u /data/xnat/home/logs/access* /data/scripts/access_logs/
find /data/xnat/home/logs/  -type f -mtime +10 -delete
find /data/xnat/cache/DELETED/    -type f -mtime +5  -delete
find /data/xnat/cache/DELETED/*    -type d -mtime +5 | xargs rm -rf
find /data/xnat/cache -mindepth 1 ! -regex '^/data/xnat/cache/USERS\(/.*\)?' ! -regex '^/data/xnat/cache/archive_specification.xml\(/.*\)?'  -type f -mtime +30  -delete
find /data/xnat/cache/USERS -mindepth 1 ! -regex '^/data/xnat/cache/archive_specification.xml\(/.*\)?'  -type f -mtime +180  -delete

find /data/xnat/build/ -type f -mtime +8 -delete
find /data/xnat/build/* -type d -mtime +8 | xargs rm -rf

find /data/xnat/archive/CONTAINER_EXEC/ -type f -mtime +30 -delete
find /data/xnat/archive/CONTAINER_EXEC/* type d -mtime +30 | xargs rm -rf


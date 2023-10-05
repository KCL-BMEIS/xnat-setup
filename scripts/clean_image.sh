#!/bin/bash
#required by save_and_restore to clean to make image smaller

find ${CATALINA_HOME}/temp/ -type f -mtime +1 -delete
cp -u /data/xnat/home/logs/access* /data/scripts/access_logs/
find /data/xnat/home/logs/  -type f -mtime +1 -delete
find /data/xnat/cache/    -type f -mtime +1  -delete
find /data/xnat/cache/*    -type d -mtime +1 | xargs rm -rf
find /data/xnat/build/ -type f -mtime +1 -delete
find /data/xnat/build/* -type d -mtime +1 | xargs rm -rf


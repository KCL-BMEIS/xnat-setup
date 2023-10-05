#!/bin/bash
find ${CATALINA_HOME}/temp/ -type f -mtime +10 -delete
cp -u /data/xnat/home/logs/access* /data/scripts/access_logs/
find /data/xnat/home/logs/  -type f -mtime +10 -delete
find /data/xnat/cache/DELETED/    -type f -mtime +3  -delete
find /data/xnat/cache/DELETED/*    -type d -mtime +3 | xargs rm -rf
find /data/xnat/cache -mindepth 1 ! -regex '^/data/xnat/cache/USERS\(/.*\)?' ! -regex '^/data/xnat/cache/archive_specification.xml\(/.*\)?'  -type f -mtime +3  -delete
find /data/xnat/build/ -type f -mtime +3 -delete
find /data/xnat/build/* -type d -mtime +3 | xargs rm -rf


#find /data/xnat/archive/ -name "*.dcm" -type f -mtime +30 -delete
#find /data/xnat/archive/ -name "*.nii" -type f -mtime +30 -delete
#find /data/xnat/archive/ -name "*.bf" -type f  -mtime +30 -delete


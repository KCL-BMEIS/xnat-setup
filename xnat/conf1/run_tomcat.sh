#!/usr/bin/env bash


while true
do
    date >> /data/scripts/logs/tomcat.log
    echo "Tomcat Starting" >> /data/scripts/logs/tomcat.log
    # this does not continuosly run.... need to monitor....
    /usr/local/tomcat/bin/startup.sh
    date >> /data/scripts/logs/tomcat.log
    echo "Tomcat Stopped. Waiting 2 minutes before restarting" >> /data/scripts/logs/tomcat.log
    sleep 120
done

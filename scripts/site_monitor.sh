#! /bin/bash
# A script to monitor uptime of websites,
# and notify by email if a website is down.

# 00 * * * * /anonymiser/scripts/site_monitor.sh >> /anonymiser/site_monitor.log

SITES="http://localhost"
EMAILS="daniel.beasley@kcl.ac.uk"
for SITE in $(echo $SITES | tr "," " "); do
  if [ ! -z "${SITE}" ]; then
    RESPONSE=$(curl -s --head $SITE)
    # if tomcat running, assumes it goes to homepage
    if echo $RESPONSE | grep "/app/template/Login.v" > /dev/null
    #if echo $RESPONSE | grep "200 OK" > /dev/null
    then
      echo "The HTTP Server on ${SITE} is up!"
    else
      MESSAGE="XNAT ${SITE} has failed to respond. Restarting XNAT"
      for EMAIL in $(echo $EMAILS | tr "," " "); do
        SUBJECT="${SITE} (http) Failed"
        echo $MESSAGE | mail -s "$SUBJECT" $EMAIL
        echo $SUBJECT
        echo "Alert sent to $EMAIL"
      done
      # restart?
      su - root -c "cd /xnat-install/xnat-setup/Linux && ./restart.sh"
    fi
  fi
done

# disc space
DF=$(df -h | grep ubuntu--vg)
declare -a percent=("90%" "91%" "92%" "93%" "94%" "95%" "96%" "97%" "98%" "99%" "100%")

## now loop through the above array
for i in "${percent[@]}"
do
  if echo $DF | grep $i > /dev/null
  then
     MESSAGE="The XNAT server is running low on space: $i full"
      for EMAIL in $(echo $EMAILS | tr "," " "); do
        SUBJECT="${SITE} Space low - $i full"
        echo $MESSAGE | mail -s "$SUBJECT" $EMAIL
        echo $SUBJECT
        echo $MESSAGE
        echo "Alert sent to $EMAIL"
      done
    fi
done
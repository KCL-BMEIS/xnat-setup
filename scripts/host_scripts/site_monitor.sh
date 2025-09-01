#! /bin/bash
# A script to monitor uptime of websites,
# and notify by email if a website is down.


SITES=""
EMAILS=""
for SITE in $(echo $SITES | tr "," " "); do
  if [ ! -z "${SITE}" ]; then
    RESPONSE=$(curl -s --head $SITE)
    # if tomcat running, assumes it goes to homepage
    if echo $RESPONSE | grep "/app/template/Login.v" > /dev/null
    #if echo $RESPONSE | grep "200 OK" > /dev/null
    then
      something="1"
      #echo "The HTTP Serve
    else
      MESSAGE="XNAT ${SITE} has failed to respond. Restarting XNAT"
      for EMAIL in $(echo $EMAILS | tr "," " "); do
        SUBJECT="${SITE} (http) Failed"
        echo $MESSAGE | mail -s "$SUBJECT" $EMAIL
        echo $SUBJECT
        echo "Alert sent to $EMAIL"
      done
      # restart?
      date
      echo "Restarting XNAT Server"
      cd /xnat-install/xnat-setup/Linux && ./restart.sh
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
     date
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
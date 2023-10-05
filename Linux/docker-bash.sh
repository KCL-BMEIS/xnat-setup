#!/usr/bin/env bash
LINE=$(docker ps | egrep xnat-web | cut -c1-12)
echo "$LINE"
#docker exec -it "$LINE" /bin/bash  


docker exec -it "$LINE" /bin/bash

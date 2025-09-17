# perform on host

LINE=$(docker ps | egrep xnat-nginx | cut -c1-12)
echo "Logging into nginx container: $LINE"
docker exec -it "$LINE" /bin/sh -c "logrotate -vf /etc/logrotate.d/nginx && ls /var/log/nginx"
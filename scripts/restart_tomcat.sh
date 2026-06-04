rm -f /data/xnat/home/plugins/*.jar
mv /data/scripts/plugins/*.jar /data/xnat/home/plugins/
chmod -R 775 /data/xnat/home/plugins/
#if replacing logo...
cp /data/scripts/logo.png /usr/local/tomcat/webapps/ROOT/images/
/usr/local/tomcat/bin/startup.sh
timeout 300 tail -f /usr/local/tomcat/logs/catalina.out
# vulnerabilities in temrurin - focal is ubuntu 20.04 - Jammy is 22.04 - noble 24.04
# correctto is openjdk image by amazon
FROM  tomcat:9.0.115-jdk21-temurin-noble
#FROM  tomcat:9-jdk21-temurin-noble

#PROXY - fill in ip:port of proxy
#ENV http_proxy   "@PROXYURL@:@PROXYPORT@"
#ENV HTTP_PROXY   "@PROXYURL@:@PROXYPORT@"
#ENV https_proxy  "@PROXYURL@:@PROXYPORT@"
#ENV HTTPS_PROXY  "@PROXYURL@:@PROXYPORT@"
#ENV ftp_proxy    "@PROXYURL@:@PROXYPORT@"
#ENV FTP_PROXY    "@PROXYURL@:@PROXYPORT@"
#ENV no_proxy    "localhost,@URLNAME@,127.0.0.1,xnat-web"
#ENV NO_PROXY    "localhost,@URLNAME@,127.0.0.1,xnat-web"
ARG XNAT_VERSION
ENV XNAT_VER=$XNAT_VERSION
ARG TIMEZONE
#takes timezone from host in build.sh
ENV TZ=$TIMEZONE
ARG XNAT_ROOT=/data/xnat
ARG XNAT_HOME=/data/xnat/home
ARG TOMCAT_XNAT_FOLDER=ROOT
ARG TOMCAT_XNAT_FOLDER_PATH=${CATALINA_HOME}/webapps/${TOMCAT_XNAT_FOLDER}

# Fix sh and install dependencies
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN export DEBIAN_FRONTEND=noninteractive && export TZ=${TZ}  \
    && apt-get -yq update && apt-get -yq install dcmtk dos2unix mc cron curl python3 python3-pip zip jq  postgresql-client-16 tzdata

# sets timezone so matches host
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && dpkg-reconfigure -f noninteractive tzdata



#RUN adduser --quiet --disabled-password --shell /bin/bash --home /data/xnat/home/ --gecos "User" xnat
RUN mkdir -p /data/xnat/home/logs /data/xnat/home/plugins /data/xnat/home/work /data/xnat/home/config/auth /data/xnat/archive /data/xnat/build /data/xnat/cache /data/xnat/ftp /data/xnat/prearchive /data/xnat/fileStore /data/xnat/inbox

ADD conf1/setenv.sh ${CATALINA_HOME}/bin
RUN chmod 775 ${CATALINA_HOME}/bin/setenv.sh ${CATALINA_HOME}/bin/catalina.sh


# Add files
ADD conf1/xnat-conf.properties /data/xnat/home/config
ADD conf1/prefs-init.ini /data/xnat/home/config
ADD conf1/siteConfig.txt /data/xnat/home
ADD conf1/setup-xnat.sh /data/xnat/
ADD conf1/run_tomcat.sh /data/xnat/
ADD xnat.cfg /data/xnat/home
#ADD bash_profile /opt/


RUN curl -L -o /tmp/xnat.war  https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VER}.war
#for testing
#ADD xnat.war /tmp/
RUN rm -rf ${CATALINA_HOME}/webapps/*
RUN mkdir ${TOMCAT_XNAT_FOLDER_PATH}
RUN unzip -o -d ${TOMCAT_XNAT_FOLDER_PATH} /tmp/xnat.war
RUN rm -f /tmp/xnat.war


RUN dos2unix /data/xnat/*
RUN dos2unix /data/xnat/home/*
RUN chmod 775 /data/xnat/setup-xnat.sh /data/xnat/run_tomcat.sh
RUN chmod -R 770 /data/xnat/home

RUN apt-get -yq update && apt -yq install python3-pydicom python3-docopt python3-lxml python3-requests

# if ldap:
# ADD conf1/ldap-provider.properties /data/xnat/home/config

ENV XNAT_HOME=${XNAT_HOME}

# Launch Tomcat
CMD ["/data/xnat/setup-xnat.sh"]




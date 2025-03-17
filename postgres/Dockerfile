FROM postgres:16
#neeedd to ensure host and containers have the same time
ARG TIMEZONE
#RUN apk add tzdata
RUN apt-get install tzdata
ENV TZ=$TIMEZONE

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
# not in alpine - && dpkg-reconfigure -f noninteractive tzdata

# debian:
#FROM postgres:16
#RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8
#ENV LANG de_DE.utf8
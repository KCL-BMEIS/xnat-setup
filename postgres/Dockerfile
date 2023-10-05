FROM postgres:12-alpine
#neeedd to ensure host and containers have the same time
ARG TIMEZONE
RUN apk add tzdata
ENV TZ=$TIMEZONE

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
# not in alpine - && dpkg-reconfigure -f noninteractive tzdata
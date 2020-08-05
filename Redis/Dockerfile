FROM alpine:latest
MAINTAINER whohow20094702 <whohow20094702@163.com>

RUN apk upgrade --update && \
    apk add redis && \
    sed -i '/^daemonize/s/yes/no/g' /etc/redis.conf && \
    sed -i 's/^logfile/#logfile/g' /etc/redis.conf

COPY gosu /bin/gosu
RUN ["chmod","+x","/bin/gosu"]

ADD entrypoint.sh /entrypoint.sh
RUN ["chmod","+x","/entrypoint.sh"]

VOLUME /var/lib/redis
EXPOSE 6379

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]

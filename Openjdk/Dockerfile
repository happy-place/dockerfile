FROM alpine:latest
MAINTAINER whohow20094702 <whohow20094702@163.com>

ADD .bashrc /root/
RUN set -x \
    apk update \
    && apk add --no-cache bash bash-doc bash-completion openjdk8-jre su-exec \
    && sed -i 's/ash/bash/g' /etc/passwd \
    && source /root/.bashrc

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:$JAVA_HOME/bin

WORKDIR /opt

VOLUME ["/opt"]

CMD ["/bin/bash"]

#ENTRYPOINT ["/elastic-entrypoint.sh"]
#CMD ["elasticsearch"]
#HEALTHCHECK CMD ["docker-healthcheck"]

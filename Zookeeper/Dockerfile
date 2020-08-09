# using alpine-glibc instead of alpine  is mainly because JDK relies on glibc
FROM whohow20094702/openjdk-1.8:v1.0
# author
MAINTAINER whohow20094702 <whohow20094702@163.com>
# A streamlined jre
ADD zookeeper-3.6.1.tar.gz /opt/zookeeper-3.6.1
# set env
ENV ZOOKEEPER_HOME /opt/zookeeper-3.6.1
ENV ZOOPIDFILE ${ZOOKEEPER_HOME}/data/zookeeper_server.pid
ENV PATH ${PATH}:${ZOOKEEPER_HOME}/bin

# run container with base path:/opt
WORKDIR /opt
# start zookeeper
CMD ["bash","-c","${ZOOKEEPER_HOME}/bin/zookeeper start-foreground"]

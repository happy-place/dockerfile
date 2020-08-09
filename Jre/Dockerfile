# using alpine-glibc instead of alpine  is mainly because JDK relies on glibc
FROM whohow20094702/alpine-glibc:v1.0
# author
MAINTAINER whohow20094702 <whohow20094702@163.com>

RUN apk add --no-cache openjdk8-jre su-exec

# A streamlined jre
ADD jre1.8.0_262.tar.gz /usr/java/jre/
# set env
ENV JAVA_HOME /usr/java/jre
ENV PATH ${PATH}:${JAVA_HOME}/bin
# run container with base path:/opt
WORKDIR /opt

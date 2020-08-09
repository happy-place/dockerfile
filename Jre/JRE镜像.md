# JRE镜像

*下载 [jdk](https://www.java.com/en/download/manual.jsp)*

*未瘦身*

```shell
cd WORKDIR && mkdir jre && cd jre && mkdir packages

# 解压下载的jdk安装包
tar -zxvf jre1.8.0_261.tar.gz && mv jre1.8.0_261.tar.gz packages/

cd jre1.8.0_261 

# 进入安装包内打包
tar -zcvf jre1.8.0_261.tar.gz * && mv jre1.8.0_261.tar.gz .. && cd ..

vi Dockerfile
## -----------------------------------------------------------------------------
# using alpine-glibc instead of alpine  is mainly because JDK relies on glibc
FROM whohow20094702/alpine-glibc:v1.0
# author
MAINTAINER whohow20094702 <whohow20094702@163.com>
# A streamlined jre
ADD jre1.8.0_261.tar.gz /usr/java/jdk/
# set env
ENV JAVA_HOME /usr/java/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin
# run container with base path:/opt
WORKDIR /opt
## -----------------------------------------------------------------------------

docker build -t alpine-glibc/jre1.8:v1.0 .

docker images | grep jre
#alpine-glibc/jre1.8        v1.0                56e4eee6af4b        12 seconds ago      268MB

# docker hub 创建仓库 whohow20094702/jre1.8

# 本地镜像映射远程仓库
docker tag alpine-glibc/jre1.8:v1.0 whohow20094702/jre1.8:v1.0

# 本地镜像推送远程仓库
docker push whohow20094702/jre1.8:v1.0

# 删除本地镜像，然后尝试从远程获取
docker rmi alpine-glibc/jre1.8:v1.0 whohow20094702/jre1.8:v1.0
docker pull whohow20094702/jre1.8:v1.0

docker images | grep jre
# whohow20094702/jre1.8         v1.0             56e4eee6af4b        9 minutes ago       268MB

# 测试 java
docker run -itd --name jre1 whohow20094702/jre1.8:v1.0
docker exec -it jre1 sh -c "java -version"
#java version "1.8.0_261"
#Java(TM) SE Runtime Environment (build 1.8.0_261-b12)
#Java HotSpot(TM) 64-Bit Server VM (build 25.261-b12, mixed mode)
```
*已瘦身*

```shell
# 解压下载的jdk安装包
tar -zxvf jre1.8.0_261.tar.gz && rm -rf jre1.8.0_261.tar.gz

cd jre1.8.0_261 

# 瘦身
rm -rf COPYRIGHT LICENSE README release THIRDPARTYLICENSEREADME-JAVAFX.txt THIRDPARTYLICENSEREADME.txt Welcome.html
rm -rf lib/plugin.jar \
lib/ext/jfxrt.jar \
bin/javaws \
lib/javaws.jar \
lib/desktop \
plugin \
lib/deploy* \
lib/*javafx* \
lib/*jfx* \
lib/amd64/libdecora_sse.so \
lib/amd64/libprism_*.so \
lib/amd64/libfxplugins.so \
lib/amd64/libglass.so \
lib/amd64/libgstreamer-lite.so \
lib/amd64/libjavafx*.so \
lib/amd64/libjfx*.so

# 进入安装包内打包
tar -zcvf jre1.8.0_262.tar.gz * && mv jre1.8.0_262.tar.gz .. && cd ..

vi Dockerfile
## -----------------------------------------------------------------------------
# using alpine-glibc instead of alpine  is mainly because JDK relies on glibc
FROM  whohow20094702/alpine-glibc:v1.0
# author
MAINTAINER whohow20094702 <whohow20094702@163.com>
# A streamlined jre
ADD jre1.8.0_262.tar.gz /usr/java/jdk/
# set env
ENV JAVA_HOME /usr/java/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin
# run container with base path:/opt
WORKDIR /opt
## -----------------------------------------------------------------------------

docker build -t alpine-glibc/jre1.8:v2.0 .

docker images | grep jre
#alpine-glibc/jre1.8           v2.0           0bd1ff6a4546        5 seconds ago       143MB

# 本地镜像映射远程仓库
docker tag alpine-glibc/jre1.8:v2.0 whohow20094702/jre1.8:v2.0

# 本地镜像推送远程仓库
docker push whohow20094702/jre1.8:v2.0

# 删除本地镜像，然后尝试从远程获取
docker rmi alpine-glibc/jre1.8:v2.0 whohow20094702/jre1.8:v2.0
docker pull whohow20094702/jre1.8:v2.0

docker images | grep jre
#whohow20094702/jre1.8         v2.0              0bd1ff6a4546        4 minutes ago       143MB
#whohow20094702/jre1.8         v1.0              56e4eee6af4b        17 minutes ago      268MB

# 测试 java
docker run -itd --name jre2 whohow20094702/jre1.8:v2.0
docker exec -it jre2 sh -c "java -version"
#java version "1.8.0_261"
#Java(TM) SE Runtime Environment (build 1.8.0_261-b12)
#Java HotSpot(TM) 64-Bit Server VM (build 25.261-b12, mixed mode)
```


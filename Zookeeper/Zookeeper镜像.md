# Zookeeper 镜像

```shell
cd WORKDIR && mkdir zookeeper && cd zookeeper && mkdir packages

# 下载 zookeeper-3.6.1.tar.gz
tar -zxvf zookeeper-3.6.1.tar.gz && mv zookeeper-3.6.1.tar.gz packages/

cd zookeeper-3.6.1

rm -rf bin/*.bat release lib/*LICENSE.txt
mkdir data logs

echo 1 > data/myid

mv conf/zoo_sample.cfg conf/zoo.cfg 
vi conf/zoo.cfg
## ----------------------------------------------------------------------
dataDir=/opt/zookeeper-3.6.1/data
dataLogDir=/opt/zookeeper-3.6.1/logs
server.1=localhost:2888:3888
## ---------------------------------------------------------------------

# 辅助脚本
vi bin/zookeeper
## ----------------------------------------------------------------------
#!/bin/bash

case $1 in
	start)
		$ZOOKEEPER_HOME/bin/zkServer.sh start
	;;
	start-foreground)
        $ZOOKEEPER_HOME/bin/zkServer.sh start-foreground
    ;;
	stop)
		$ZOOKEEPER_HOME/bin/zkServer.sh stop
	;;
	status)
	    $ZOOKEEPER_HOME/bin/zkServer.sh status
	;;
	restart)
		$ZOOKEEPER_HOME/bin/zkServer.sh restart
	;;
	client)
		$ZOOKEEPER_HOME/bin/zkCli.sh
	;;
	remote_client)
		$ZOOKEEPER_HOME/bin/zkCli.sh -server $server
	;;
	*)
		echo '启动: zookeeper start'
		echo '启动并阻塞: zookeeper start-foreground'
		echo '关闭: zookeeper stop'
		echo '状态: zookeeper status'
		echo '重启: zookeeper restart'
		echo '客户端: zookeeper client'
		echo '远程客户端: zookeeper remote_client $server'
	;;
esac

exit 0
## ----------------------------------------------------------------------

# 175 行替换成如下形式
vi bin/zkServer.sh
## ----------------------------------------------------------------------
        sleep 1
        # pid=$(cat "${ZOOPIDFILE}")
        count=`ps -ef | grep zookeeper | grep -v "grep" | wc -l`
        if [ $count -gt 1 ]; then
## ----------------------------------------------------------------------

tar -zcvf zookeeper-3.6.1.tar.gz * && mv zookeeper-3.6.1.tar.gz .. && cd ..

vi Dockerfile
## ----------------------------------------------------------------------
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
CMD ["bash","-c","${ZOOKEEPER_HOME}/bin/zookeeper","start-foreground"]
## ----------------------------------------------------------------------

docker build -t zookeeper-3.6.1:v1.0 .

# docker hub 创建仓库 whohow20094702/zookeeper-3.6.1

# 本地镜像映射远程仓库
docker tag zookeeper-3.6.1:v1.0 whohow20094702/zookeeper-3.6.1:v1.0

# 本地镜像推送远程仓库
docker push whohow20094702/zookeeper-3.6.1:v1.0

# 删除本地镜像，然后尝试从远程获取
docker rmi zookeeper-3.6.1:v1.0 whohow20094702/zookeeper-3.6.1:v1.0
docker pull whohow20094702/zookeeper-3.6.1:v1.0

docker images | grep zookeeper-3.6.1
#whohow20094702/zookeeper-3.6.1  v1.0  4726e882f717  8 minutes ago   102MB

# 测试 zookeeper
docker run -itd --name zookeeper whohow20094702/zookeeper-3.6.1:v1.0
docker exec -it zookeeper bash -c "zookeeper status"
#ZooKeeper JMX enabled by default
#Using config: /opt/zookeeper-3.6.1/bin/../conf/zoo.cfg
#Client port found: 2181. Client address: localhost.
#Mode: standalone
```



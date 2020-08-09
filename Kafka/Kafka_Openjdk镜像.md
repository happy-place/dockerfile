# Kafka镜像
*注*: 基于 Openjdk 构建镜像，体积偏小，基本功能可用，存在部分缺陷就是，无法使用 RUN chmod +x xxx 调整权限，kafka status 执行正常，但无输出，对应whohow20094702/kafka_2.12-2.5.0:v2.0。

```shell
# 下载 kafka_2.12-2.5.0.tar.gz 
cd WORKDIR && mkdir kafka && cd kafka && mkdir packages

tar -zxvf kafka_2.12-2.5.0.tar.gz  && cd kafka_2.12-2.5.0 && mv kafka_2.12-2.5.0.tar.gz packages/

rm -rf LICENSE NOTICE site-docs lib/*jar.asc lib/*sources.jar bin/windows

vi config/server.properties
##--------------------------------------------------------------------
log.dirs=/opt/kafka_2.12-2.5.0/logs
# 等待启动时替换
zookeeper.connect=localhost:2181
log.retention.hours=168
##--------------------------------------------------------------------

vi bin/server-prop-init.sh
##--------------------------------------------------------------------
#!/bin/bash

if [ $ZOOKEEPER_HOST ];then
  sed -i "s/zookeeper.connect=localhost:2181/zookeeper.connect=$ZOOKEEPER_HOST/" $KAFKA_HOME/config/server.properties
else
  echo '$ZOOKEEPER_HOST is not setted.'
  exit 1
fi

if [ $ZOOKEEPER_HOST ];then
  sed -i "s/log.retention.hours=168/log.retention.hours=$LOG_RETENTION_HOURS/" $KAFKA_HOME/config/server.properties
fi

exit 0
##--------------------------------------------------------------------

vi bin/kafka
##--------------------------------------------------------------------
#!/bin/bash

BROKER=localhost:9092

case $1 in
    start)
		$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
	;;
	start-daemon)
		$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
	;;
	stop)
		$KAFKA_HOME/bin/kafka-server-stop.sh
	;;
	status)
			ps -ef | grep kafka | grep -v grep | awk -F ' ' '{print $1}'
	;;
	restart)
		$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
		$KAFKA_HOME/bin/kafka-server-stop.sh
	;;
	list_topics)
		$KAFKA_HOME/bin/kafka-topics.sh --list --zookeeper $ZOOKEEPER_HOST
	;;
	create_topic)
		$KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER_HOST --topic $2 --partitions $3 --replication-factor $4
	;;
	del_topic)
		$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZOOKEEPER_HOST --topic $2 --delete
	;;
	increase_partition)
		$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZOOKEEPER_HOST --alter --topic $2 --partitions $3
	;;
	reblance)
		$KAFKA_HOME/bin/kafka-preferred-replica-election.sh --bootstrap-server $BROKER
	;;
	produce)
		$KAFKA_HOME/bin/kafka-console-producer.sh --broker-list $BROKER --topic $2
	;;
	consume_from_begin)
		$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server $BROKER --topic $2 --from-beginning
    ;;
    consume_from_latest)
    	$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server $BROKER --topic $2 --offset latest --partition $3
    ;;
    consume_from_latest_x)
    	$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server $BROKER --topic $2 --offset latest --partition $3 --max-messages $4
    ;;
    min_offset)
    	$KAFKA_HOME/bin/kafka-run-class.sh kafka.tools.GetOffsetShell --topic $2 --time -2 --broker-list $BROKER --partitions $3
    ;;
    max_offset)
    	$KAFKA_HOME/bin/kafka-run-class.sh kafka.tools.GetOffsetShell --topic $2 --time -1 --broker-list $BROKER --partitions $3
    ;;
    all_groups)
    	$KAFKA_HOME/bin/kafka-consumer-groups.sh --bootstrap-server $BROKER --list
    ;;
    desc_group)
		$KAFKA_HOME/bin/kafka-consumer-groups.sh --bootstrap-server $BROKER --group $2 --describe
	;;
	del_group)
		$KAFKA_HOME/bin/kafka-consumer-groups.sh --bootstrap-server $BROKER --group $2 --delete
	;;
    del_group_topic)
		$KAFKA_HOME/bin/kafka-consumer-groups.sh --bootstrap-server $BROKER --group $2 --topic $3 --delete
	;;
	random_produce)
		$KAFKA_HOME/bin/kafka-producer-perf-test.sh --topic $2 --num-records $3 --record-size $4 --throughput $3 --producer-props bootstrap.servers=$BROKER
	;;
	*)
		echo '启动并阻塞: kafka start'
		echo '后台启动: kafka start-daemon'
		echo '关闭: kafka stop'
		echo '状态: kafka status'
		echo '重启: kafka restart'
		echo '列举topics: kafka list_topics'
		echo '创建topic: kafka create_topic $topic $partitions $replication'
		echo '删除topic: kafka del_topic $topic'
		echo '修改topic分区: kafka increase_partition $topic $partitions'
		echo '重新平衡leader: kafka reblance'
		echo '生成消息: kafka produce $topic'
		echo '从最早消费: kafka consume_from_begin $topic'
		echo '从指定分区最新消费: kafka consume_from_latest $topic $partition'
		echo '从指定分区最新消费x条: kafka consume_from_latest_x $topic $partition $records'
		echo '查看topic指定分区最小offset: kafka min_offset $topic $partition'
		echo '查看topic指定区最大offset: kafka max_offset $topic $partition'
		echo '查看全部消费组: kafka all_groups'
		echo '描述指定消费组: kafka desc_group $group'
		echo '删除指定消费组: kafka del_group $group'
		echo '删除消费组中指定topic消息信息: kafka del_group_topic $group $topic'
		echo '生产压测: kafka random_produce $topic $records $length '
	;;
esac

exit 0
##--------------------------------------------------------------------

mkdir logs

tar -zcvf kafka_2.12-2.5.0.tar.gz * && mv kafka_2.12-2.5.0.tar.gz .. && cd ..

vi Dockerfile
##--------------------------------------------------------------------
FROM whohow20094702/openjdk-1.8:v1.0
# author
MAINTAINER whohow20094702 <whohow20094702@163.com>

ADD kafka_2.12-2.5.0.tar.gz /opt/kafka_2.12-2.5.0

ENV KAFKA_HOME /opt/kafka_2.12-2.5.0
ENV PATH ${PATH}:${KAFKA_HOME}/bin

WORKDIR /opt

CMD ["bash","-c","cd /opt/kafka_2.12-2.5.0/bin && chmod +x server-prop-init.sh && server-prop-init.sh && kafka start"]
##--------------------------------------------------------------------

docker build -t kafka_2.12-2.5.0:v1.0 .

# docker hub 创建仓库 whohow20094702/kafka_2.12-2.5.0

# 本地镜像映射远程仓库
docker tag kafka_2.12-2.5.0:v1.0 whohow20094702/kafka_2.12-2.5.0:v1.0

# 本地镜像推送远程仓库
docker push whohow20094702/kafka_2.12-2.5.0:v1.0

# 删除本地镜像，然后尝试从远程获取
docker rmi kafka_2.12-2.5.0:v1.0 whohow20094702/kafka_2.12-2.5.0:v1.0
docker pull whohow20094702/kafka_2.12-2.5.0:v1.0

# 注 FROM whohow20094702/jre1.8:v2.0


docker images | grep kafka
#whohow20094702/kafka_2.12-2.5.0   v1.0  1568ef4a50b9      22 minutes ago      204MB
#canal/kafka-sink                   1.0  f9d58f06fe81      2 weeks ago         474MB
#wurstmeister/kafka              latest  988f4a6ca13c      13 months ago       421MB

# 先启动 zookeeper
docker run -itd \
--name zookeeper \
--net canal-net \
--ip 172.18.0.6 \
-p 2181:2181 \
whohow20094702/zookeeper-3.6.1:v1.0

docker exec -it zookeeper bash -c 'zookeeper status'
#ZooKeeper JMX enabled by default
#Using config: /opt/zookeeper-3.6.1/bin/../conf/zoo.cfg
#Client port found: 2181. Client address: localhost.
#Mode: standalone

# 启动 kafka
docker run -itd \
--name kafka \
--net canal-net \
--ip 172.18.0.7 \
-p 9092:9092 \
-e ZOOKEEPER_HOST=172.18.0.6:2181 \
-e LOG_RETENTION_HOURS=200 \
whohow20094702/kafka_2.12-2.5.0:v1.0

docker exec -it kafka bash -c 'cat $KAFKA_HOME/config/server.properties | grep zookeeper.connect='
# zookeeper.connect=172.18.0.6:2181

docker exec -it kafka bash -c 'kafka create_topic test 3 1'
# Created topic test.
```

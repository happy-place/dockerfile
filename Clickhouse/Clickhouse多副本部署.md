# mysql 数据同步 clickhouse 测试

```text
1) mysql5.6 向 clichouse-20.12.3.3 单体同步；
2) mysql5.7 向 clichouse-20.12.3.3 单体同步；
4) mysql5.6 向 clichouse-20.12.3.3 主从集群同步；
3) mysql5.7 向 clichouse-20.12.3.3 主从集群同步；
节点 ip 备注
```

网络规划

| 节点      | IP           | 备注                                   |
| --------- | ------------ | -------------------------------------- |
| fix-net   | 192.168.0.1  | 自定义网关                             |
| mysql5.6  | 192.168.0.2  | Ver 14.14 Distrib 5.6.50 、端口：3306  |
| mysql5.7  | 192.168.0.3  | Ver 14.14 Distrib 5.7.32、端口：3307   |
| ck-single | 192.168.0.4  | 20.12.3.3、端口：9000、8123、9009      |
| ck-node1  | 192.168.0.5  | 20.12.3.3、端口：9001、8124、9010      |
| ck-node2  | 192.168.0.6  | 20.12.3.3、端口：9002、8125、9011      |
| ck-node3  | 192.168.0.7  | 20.12.3.3、端口：9003、8126、9012      |
| ck-node4  | 192.168.0.8  | 20.12.3.3、端口：9004、8127、9013      |
| zk        | 192.168.0.9  | apache-zookeeper-3.6.2-bin、端口：2181 |
| zkui      | 192.168.0.10 | 可视化、端口：9090                     |



## 下载镜像

```shell
# 下载 clickhouse 20.12.3.3
docker pull yandex/clickhouse-server

# boss_stats 为 mysql:5.7.25
docker pull mysql:5.7

# svc_tree 为mysql:5.6.16，未找到相关镜像，使用5.6
docker pull mysql:5.6 

# clickhouse 多节点部署需要zk
docker pull zookeeper
# 方便查看 zk-tree
docker pull registry.cn-hangzhou.aliyuncs.com/wkaca7114/zkui

# 设置docker配置目录
mkdir /Users/huhao/software/docker_place
export DOCKERPLACE=/Users/huhao/software/docker_place

# 存储 docker 镜像配置
mkdir $DOCKERPLACE/{clickhouse-20.12.3.3,mysql-5.6,mysql-5.7.25,zookeeper,zkui}
```

## 创建网络

```shell
# 为避免 docker 启动顺序导致 IP 浮动，需要设置固定 IP
docker network create --driver bridge --subnet 192.168.0.0/16 --gateway 192.168.0.1 fix-net

docker network ls
# 4950bbee8239        fix-net             bridge              local
```

## 部署mysql 

### 5.6

```shell
# 创建配置目录
mkdir $DOCKERPLACE/mysql-5.6/{conf,logs,data}

# 启动容器
docker run -d \
--name mysql5.6 \
-v $DOCKERPLACE/mysql-5.6/conf:/etc/mysql/conf.d \
-v $DOCKERPLACE/mysql-5.6/logs:/logs \
-v $DOCKERPLACE/mysql-5.6/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=root \
-p 3306:3306 \
--net fix-net \
--ip 192.168.0.2 \
mysql:5.6

docker ps | grep mysql5.6

docker exec mysql5.6 bash -c "mysql -uroot -proot -e 'status'"
# mysql  Ver 14.14 Distrib 5.6.50, for Linux (x86_64) using  EditLine wrapper

# 发现未启用 binlog
show variables like 'log_bin';
# OFF

# 开启 binlog
vi $DOCKERPLACE/mysql-5.6/conf
# --------------------------------
[mysqld]
server-id = 1
log-bin = /var/lib/mysql/mysql5.6-bin.log
expire-logs-days = 14
max-binlog-size = 500M
binlog_format = ROW 
gtid-mode = ON
enforce_gtid_consistency = 1
log-slave-updates = 1
log-bin = mysql-bin
log-bin-index = /var/lib/mysql/mysql5.6-bin.index
# --------------------------------

# 重启才能生效
docker restart mysql5.6

show variables like 'log_bin';
# ON

# 查看binlog位置
show master status ;
#+-------------+--------+------------+----------------+-----------------+
#|File         |Position|Binlog_Do_DB|Binlog_Ignore_DB|Executed_Gtid_Set|
#+-------------+--------+------------+----------------+-----------------+
#|mysql5.000001|120     |            |                |                 |
#+-------------+--------+------------+----------------+-----------------+

# 登录 mysql
mysql -uroot -proot 

# 建库
CREATE DATABASE IF NOT EXISTS test DEFAULT CHARSET utf8 COLLATE utf8_general_ci;

# 建表
create table test.student (
    id int(6) primary key auto_increment comment '自增 ID',
    name varchar(50) comment '名称',
    age int(2) comment '年龄'
);

# 插入数据
insert into test.student (name,age) values ('a1',21),('a2',21);
```

### 5.7

```shell
# 创建配置目录
mkdir $DOCKERPLACE/mysql-5.7/{conf,logs,data}

# 开启 binlog
vi $DOCKERPLACE/mysql-5.7/conf
# --------------------------------
[mysqld]
log-bin = /var/lib/mysql/mysql5.7-bin.log
server-id = 1
expire-logs-days = 14
max-binlog-size = 500M
binlog_format = ROW 
gtid-mode = on
enforce-gtid-consistency =1
# --------------------------------

# 运行容器
docker run -d \
--name mysql5.7 \
-v $DOCKERPLACE/mysql-5.7/conf:/etc/mysql/conf.d \
-v $DOCKERPLACE/mysql-5.7/logs:/logs \
-v $DOCKERPLACE/mysql-5.7/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=root \
-p 3307:3306 \
--net fix-net \
--ip 192.168.0.3 \
mysql:5.7

docker ps | grep mysql5.7

# 查看版本
docker exec -it mysql5.7 bash -c "mysql -uroot -proot -e 'status'"
# mysql  Ver 14.14 Distrib 5.7.32, for Linux (x86_64) using  EditLine wrapper

docker exec -it mysql

# 建表
CREATE DATABASE IF NOT EXISTS test DEFAULT CHARSET utf8 COLLATE utf8_general_ci;

# 查看是否开启binog同步
show variables like 'log_bin';
# ON

# 查看初始 binlog
show master status ;
#+------------+--------+------------+----------------+-----------------+
#|File        |Position|Binlog_Do_DB|Binlog_Ignore_DB|Executed_Gtid_Set|
#+------------+--------+------------+----------------+-----------------+
#|mysql5.7-bin|154     |            |                |                 |
#+------------+--------+------------+----------------+-----------------+

# 登录 mysql
mysql -uroot -proot 

# 建库
CREATE DATABASE IF NOT EXISTS test DEFAULT CHARSET utf8 COLLATE utf8_general_ci;

# 建表
create table test.student (
    id int(6) primary key auto_increment comment '自增 ID',
    name varchar(50) comment '名称',
    age int(2) comment '年龄'
);

# 查看建库建表后 binlog
show master status ;
#+------------+--------+------------+----------------+----------------------------------------+
#|File        |Position|Binlog_Do_DB|Binlog_Ignore_DB|Executed_Gtid_Set                       |
#+------------+--------+------------+----------------+----------------------------------------+
#|mysql5.7-bin|482     |            |                |75019bf1-4053-11eb-9929-0242ac110004:1-4|
#+------------+--------+------------+----------------+----------------------------------------+

# 插入数据
insert into test.student (name,age) values ('a1',21);

# 查看插入数据后 binlog
#+------------+--------+------------+----------------+----------------------------------------+
#|File        |Position|Binlog_Do_DB|Binlog_Ignore_DB|Executed_Gtid_Set                       |
#+------------+--------+------------+----------------+----------------------------------------+
#|mysql5.7-bin|752     |            |                |75019bf1-4053-11eb-9929-0242ac110004:1-5|
#+------------+--------+------------+----------------+----------------------------------------+
```

## 单体测试

### 部署clickhouse 单体

```shell
# 试运行
docker run -d \
--name ck-single \
--ulimit nofile=262144:262144 \
-p 9000:9000 \
-p 8123:8123 \
-p 9009:9009 \
--ulimit nofile=262144:262144 \
--net fix-net \
--ip 192.168.0.4 \
yandex/clickhouse-server

# 测试
docker exec -it ck-single bash -c "clickhouse-client -q 'select version()'"
# 20.12.3.3

# 设置环境变量
export CLICKHOUSE_PLACE=$DOCKERPLACE/clickhouse-20.12.3.3

# 升级权限，方便稍后拷贝配置
docker exec -it ck-single bash 
chmod -R 777 /etc/clickhouse-server
chmod -R 777 /var/lib/clickhouse

# 创建临时目录
mkdir -p $CLICKHOUSE_PLACE/single/

# 拷贝配置
docker cp ck-single:/etc/clickhouse-server/ $CLICKHOUSE_PLACE/single/conf
docker cp ck-single:/var/lib/clickhouse/ $CLICKHOUSE_PLACE/single/lib

# 删除试运行容器
docker stop ck-single
docker rm ck-single

# 重新使用外挂配置运行（方便修改）
docker run -d \
--name ck-single \
--ulimit nofile=262144:262144 \
--volume=$CLICKHOUSE_PLACE/single/lib/:/var/lib/clickhouse/ \
--volume=$CLICKHOUSE_PLACE/single/conf/:/etc/clickhouse-server/ \
--volume=$CLICKHOUSE_PLACE/single/log/:/var/log/clickhouse-server/ \
-p 9000:9000 \
-p 8123:8123 \
-p 9009:9009 \
--ulimit nofile=262144:262144 \
--net fix-net \
--ip 192.168.0.4 \
yandex/clickhouse-server

# 等待 1 分钟

# 测试
docker exec -it ck-single bash -c "clickhouse-client -h ck-single -q 'select version()'"
# 20.12.3.3

# 登录容器
docker exec -it ck-single bash

# 登录客户端
clickhouse-client 

# 查看是否开启allow_experimental_database_materialize_mysql （0/1）
select * from system.settings where name ='allow_experimental_database_materialize_mysql';

# session级别设置
SET allow_experimental_database_materialize_mysql=1;

# 或永久设置
vi $CLICKHOUSE_PLACE/single/conf/users.xml
# ------------------------------------------
<yandex>
	<profiles>
		<default>
			<allow_experimental_database_materialize_mysql>1</allow_experimental_database_materialize_mysql>
# ------------------------------------------
```

### 同步测试

#### mysql5.7

```shell
# 登录clickhouse 容器
docker exec -it ck-single bash

# 登录 clichouse 客户端
clickhouse-client

# clickhouse 中创建mysql57_test库映射 mysql5.7的test库 （接受其发送的 binlog）
CREATE DATABASE mysql57_test ENGINE = MaterializeMySQL('mysql5.7:3306', 'test', 'root', 'root');

# 查看表
show tables from mysql57_test;
+-------+
|name   |
+-------+
|student|
+-------+

# 查看记录
select * from mysql57_test.student;
+--+----+---+
|id|name|age|
+--+----+---+
|1 |a1  |21 |
+--+----+---+

# CRUD操作测试（略）
```

mysql5.6

```shell
CREATE DATABASE mysql56_test ENGINE = MaterializeMySQL('mysql5.6:3306', 'test', 'root', 'root');
```

## 主从集群测试

### 部署zookeeper

```shell
-- 创建临时目录
mkdir -p $DOCKERPLACE/zookeeper-3.6.2/{conf,data,datalog,logs}

-- 启动节点
docker run -d \
--name zk \
-p 2181:2181 \
--net fix-net \
--ip 192.168.0.9 \
zookeeper

-- 启动节点
docker run -d \
--name zk -p 2181:2181 \
-v $DOCKERPLACE/zookeeper/conf/:/apache-zookeeper-3.6.2-bin/conf/ \
-v $DOCKERPLACE/zookeeper/data/:/data \
-v $DOCKERPLACE/zookeeper/datalog/:/datalog \
-v $DOCKERPLACE/zookeeper/logs/:/logs  \
--net fix-net \
--ip 192.168.0.9 \
zookeeper
```

### 部署zookeeper-ui

```shell
-- 创建临时目录
mkdir -p $DOCKERPLACE/zookeeper-ui

-- 启动节点
docker run -d \
--name zkui \
-p 9090:9090 \
--link zk \
-e ZK_SERVER="zk:2181" \
--net fix-net \
--ip 192.168.0.10 \
registry.cn-hangzhou.aliyuncs.com/wkaca7114/zkui
```

### 部署ck-node1

```shell
# 创建临时目录
mkdir -p $CLICKHOUSE_PLACE/master-slave/node1
cp -r $CLICKHOUSE_PLACE/single/* $CLICKHOUSE_PLACE/master-slave/node1

# 启动节点
docker run -d \
--name ck-node1 \
--ulimit nofile=262144:262144 \
--volume=$CLICKHOUSE_PLACE/master-slave/node1/lib/:/var/lib/clickhouse/ \
--volume=$CLICKHOUSE_PLACE/master-slave/node1/conf/:/etc/clickhouse-server/ \
--volume=$CLICKHOUSE_PLACE/master-slave/node1/log/:/var/log/clickhouse-server/ \
-p 9001:9000 \
-p 8124:8123 \
-p 9010:9009 \
--net fix-net \
--ip 192.168.0.5 \
yandex/clickhouse-server

# 等待 1 分钟

# 测试
docker exec -it ck-node1 bash -c "clickhouse-client -h ck-node1 -q 'select version()'"
# 20.12.3.3

# 配置密码 
# default/default，如需创建其他用户，拷贝 <default> 更名为 <admin> 即可获得 admin 用户
vi $CLICKHOUSE_PLACE/master-slave/node1/conf/users.xml
# -----------------------------------------------------
<users>
	<default>
	  <allow_experimental_database_materialize_mysql>1</allow_experimental_database_materialize_mysql>
		<password>default</password>
# -----------------------------------------------------

# 配置 集群
vi $CLICKHOUSE_PLACE/master-slave/node1/conf/config.xml
# -----------------------------------------------------
    <!-- 使用主机名访问 -->
		<interserver_http_host>ck-node01</interserver_http_host>
		<!-- 自行在最后添加 -->
    <include_from>/etc/clickhouse-server/metrika.xml</include_from>
    <timezone>Asia/Shanghai</timezone>
</yandex>
# -----------------------------------------------------

# 等同于创建/etc/clickhouse-server/metrika.xml
vi $CLICKHOUSE_PLACE/master-slave/node1/conf/metrika.xml
```

```xml
<yandex>
    <!--ck集群节点-->
    <clickhouse_remote_servers>
		<clickhouse_cluster_name> <!-- TODO 集群名称，可以自定义 -->
			<!--分片1 相互备份 -->
			<shard>
			    <internal_replication>true</internal_replication>
			    <replica>
			        <host>ck-node1</host> 
			        <port>9000</port>
			        <user>default</user>
			        <password>default</password>
			    </replica>
			    <replica>
			        <host>ck-node3</host> 
			        <port>9000</port>
			        <user>default</user>
			        <password>default</password>
			    </replica>
			</shard>
			<!--分片2 相互备份 -->
			<shard>
			    <internal_replication>true</internal_replication>
			    <replica>
			        <host>ck-node2</host> 
			        <port>9000</port>
			        <user>default</user>
			        <password>default</password>
			    </replica>
			    <replica>
			        <host>ck-node4</host> 
			        <port>9000</port>
			        <user>default</user>
			        <password>default</password>
			    </replica>
			</shard>
			</clickhouse_cluster_name>  <!-- TODO 集群名称，可以自定义 -->
    </clickhouse_remote_servers>

	<!--zookeeper相关配置-->
	<zookeeper-servers>
	  <node index="1">
		<host>zk</host>
		<port>2181</port>
	  </node>
	</zookeeper-servers>
	
	<macros>
		<layer>01</layer>
		<shard>01</shard> <!-- TODO 这个节点配置的分片号-->
		<replica>ck-node1</replica> <!-- TODO 当前节点IP-->
	</macros>
	
	<networks>
		<ip>::/0</ip>
	</networks>
	
	<!--压缩相关配置-->
	<clickhouse_compression>
		<case>
			<min_part_size>10000000000</min_part_size>
			<min_part_size_ratio>0.01</min_part_size_ratio>
			<method>lz4</method> <!--压缩算法lz4压缩比zstd快, 更占磁盘-->
		</case>
	</clickhouse_compression>
</yandex>
```

### 部署ck-node2

```shell
# 创建临时目录
mkdir -p $CLICKHOUSE_PLACE/master-slave/node2
cp -r $CLICKHOUSE_PLACE/single/* $CLICKHOUSE_PLACE/master-slave/node2

# 启动节点
docker run -d \
--name ck-node2 \
--ulimit nofile=262144:262144 \
--volume=$CLICKHOUSE_PLACE/master-slave/node2/lib/:/var/lib/clickhouse/ \
--volume=$CLICKHOUSE_PLACE/master-slave/node2/conf/:/etc/clickhouse-server/ \
--volume=$CLICKHOUSE_PLACE/master-slave/node2/log/:/var/log/clickhouse-server/ \
-p 9002:9000 \
-p 8125:8123 \
-p 9011:9009 \
--net fix-net \
--ip 192.168.0.6 \
yandex/clickhouse-server

# 等待 1 分钟

# 测试
docker exec -it ck-node2 bash -c "clickhouse-client -h ck-node2 --user default --pass default -q 'select version()'"
# 20.12.3.3

# 配置密码 
# default/default，如需创建其他用户，拷贝 <default> 更名为 <admin> 即可获得 admin 用户
vi $CLICKHOUSE_PLACE/master-slave/node2/conf/users.xml
# -----------------------------------------------------
<users>
	<default>
	  <allow_experimental_database_materialize_mysql>1</allow_experimental_database_materialize_mysql>
		<password>default</password>
# -----------------------------------------------------

# 配置 集群
vi $CLICKHOUSE_PLACE/master-slave/node2/conf/config.xml
# -----------------------------------------------------
    <!-- 使用主机名访问 -->
		<interserver_http_host>ck-node02</interserver_http_host>
		<!-- 自行在最后添加 -->
    <include_from>/etc/clickhouse-server/metrika.xml</include_from>
    <timezone>Asia/Shanghai</timezone>
</yandex>
# -----------------------------------------------------

# 等同于创建/etc/clickhouse-server/metrika.xml
vi $CLICKHOUSE_PLACE/master-slave/node2/conf/metrika.xml
# -----------------------------------------------------
	<macros>
		<layer>01</layer>
		<shard>02</shard> <!-- TODO 这个节点配置的分片号-->
		<replica>ck-node2</replica> <!-- TODO 当前节点IP-->
	</macros>
# -----------------------------------------------------
```

### 部署ck-node3

```shell
-- 创建临时目录
mkdir -p $CLICKHOUSE_PLACE/master-slave/node3
cp -r $CLICKHOUSE_PLACE/single/* $CLICKHOUSE_PLACE/master-slave/node3

# 启动节点
docker run -d \
--name ck-node3 \
--ulimit nofile=262144:262144 \
--volume=$CLICKHOUSE_PLACE/master-slave/node3/lib/:/var/lib/clickhouse/ \
--volume=$CLICKHOUSE_PLACE/master-slave/node3/conf/:/etc/clickhouse-server/ \
--volume=$CLICKHOUSE_PLACE/master-slave/node3/log/:/var/log/clickhouse-server/ \
-p 9003:9000 \
-p 8126:8123 \
-p 9012:9009 \
--net fix-net \
--ip 192.168.0.7 \
yandex/clickhouse-server

# 等待 1 分钟

# 测试
docker exec -it ck-node3 bash -c "clickhouse-client -h ck-node3 -q 'select version()'"
# 20.12.3.3

# 配置密码 
# default/default，如需创建其他用户，拷贝 <default> 更名为 <admin> 即可获得 admin 用户
vi $CLICKHOUSE_PLACE/master-slave/node3/conf/users.xml
# -----------------------------------------------------
<users>
	<default>
	  <allow_experimental_database_materialize_mysql>1</allow_experimental_database_materialize_mysql>
		<password>default</password>
# -----------------------------------------------------

# 配置 集群
vi $CLICKHOUSE_PLACE/master-slave/node3/conf/config.xml
# -----------------------------------------------------
    <!-- 使用主机名访问 -->
		<interserver_http_host>ck-node03</interserver_http_host>
		<!-- 自行在最后添加 -->
    <include_from>/etc/clickhouse-server/metrika.xml</include_from>
    <timezone>Asia/Shanghai</timezone>
</yandex>
# -----------------------------------------------------

# 等同于创建/etc/clickhouse-server/metrika.xml
vi $CLICKHOUSE_PLACE/master-slave/node3/conf/metrika.xml
# -----------------------------------------------------
	<macros>
		<layer>01</layer>
		<shard>01</shard> <!-- TODO 这个节点配置的分片号-->
		<replica>ck-node3</replica> <!-- TODO 当前节点IP-->
	</macros>
# -----------------------------------------------------
```

### 部署ck-node4

```shell
# 创建临时目录
mkdir -p $CLICKHOUSE_PLACE/master-slave/node4
cp -r $CLICKHOUSE_PLACE/single/* $CLICKHOUSE_PLACE/master-slave/node4

# 启动节点
docker run -d \
--name ck-node4 \
--ulimit nofile=262144:262144 \
--volume=$CLICKHOUSE_PLACE/master-slave/node4/lib/:/var/lib/clickhouse/ \
--volume=$CLICKHOUSE_PLACE/master-slave/node4/conf/:/etc/clickhouse-server/ \
--volume=$CLICKHOUSE_PLACE/master-slave/node4/log/:/var/log/clickhouse-server/ \
-p 9004:9000 \
-p 8127:8123 \
-p 9013:9009 \
--net fix-net \
--ip 192.168.0.8 \
yandex/clickhouse-server

# 等待 1 分钟

# 测试
docker exec -it ck-node4 bash -c "clickhouse-client -h ck-node4 -q 'select version()'"
# 20.12.3.3

# 配置密码 
# default/default，如需创建其他用户，拷贝 <default> 更名为 <admin> 即可获得 admin 用户
vi $CLICKHOUSE_PLACE/master-slave/node4/conf/users.xml
# -----------------------------------------------------
<users>
	<default>
	  <allow_experimental_database_materialize_mysql>1</allow_experimental_database_materialize_mysql>
		<password>default</password>
# -----------------------------------------------------

# 配置 集群
vi $CLICKHOUSE_PLACE/master-slave/node4/conf/config.xml
# -----------------------------------------------------
    <!-- 使用主机名访问 -->
		<interserver_http_host>ck-node04</interserver_http_host>
		<!-- 自行在最后添加 -->
    <include_from>/etc/clickhouse-server/metrika.xml</include_from>
    <timezone>Asia/Shanghai</timezone>
</yandex>
# -----------------------------------------------------

# 等同于创建/etc/clickhouse-server/metrika.xml
vi $CLICKHOUSE_PLACE/master-slave/node4/conf/metrika.xml
# -----------------------------------------------------
	<macros>
		<layer>01</layer>
		<shard>02</shard> <!-- TODO 这个节点配置的分片号-->
		<replica>ck-node4</replica> <!-- TODO 当前节点IP-->
	</macros>
# -----------------------------------------------------
```

### 分布式表测试

```shell
# ReplicatedMergeTree 表所在库
drop database if exists shard ON CLUSTER "clickhouse_cluster_name";
create database IF NOT EXISTS shard ON CLUSTER "clickhouse_cluster_name";

# Distributed 表所在库
drop database  if exists all ON CLUSTER "clickhouse_cluster_name";
create database IF NOT EXISTS all ON CLUSTER "clickhouse_cluster_name";

# 所有节点创建分片表
drop table IF  EXISTS shard.orders ON CLUSTER "clickhouse_cluster_name";
CREATE TABLE shard.orders ON CLUSTER "clickhouse_cluster_name"
(
    `ldate` Date COMMENT '日期',
    `name` Nullable(String) COMMENT '名称'
) ENGINE = ReplicatedMergeTree('/clickhouse/pro/tables/shard.orders/{shard}', '{replica}')
      PARTITION BY toYYYYMM(ldate)
      ORDER BY ldate;

# 所有节点创建分布式表
drop table IF  EXISTS all.orders ON CLUSTER "clickhouse_cluster_name";
CREATE TABLE IF NOT EXISTS all.orders ON CLUSTER "clickhouse_cluster_name"
(
    `ldate` Date COMMENT '日期',
    `name` Nullable(String) COMMENT '名称'
) ENGINE = Distributed('clickhouse_cluster_name', 'shard', 'orders', rand());

# 清空制定分区数据
alter table shard.orders on cluster 'clickhouse_cluster_name' delete where ldate='2020-12-01';

# 通过分布式表，往分片表插入数据
insert into all.orders(ldate,name) values ('2020-12-01','a1'),('2020-12-01','a2'),('2020-12-01','a3');

# 查看当前节点分片数据
select * from shard.orders;
# +----------+----+
# |ldate     |name|
# +----------+----+
# |2020-12-01|a3  |
# +----------+----+

# 查看所有分片数据
select * from all.orders;
# +----------+----+
# |ldate     |name|
# +----------+----+
# |2020-12-01|a3  |
# |2020-12-01|a1  |
# |2020-12-01|a2  |
# +----------+----+
```

### 数据同步测试

#### mysql-5.7

```shell
# MaterializeMySQL 只能整个库同步
drop database mysql57_test on cluster 'clickhouse_cluster_name';
CREATE DATABASE mysql57_test ENGINE = MaterializeMySQL('mysql5.7:3306', 'test', 'root', 'root');

show databases;
show tables from mysql57_test;

# 查看数据
select * from mysql57_test.student;
# +----------+----+
# |ldate     |name|
# +----------+----+
# |2020-12-01|a3  |
# +----------+----+
```

#### mysql-5.6

```shell
# 暂未测通
```




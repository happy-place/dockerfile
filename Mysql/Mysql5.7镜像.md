*注*: 官方镜像mysql:5.7.26 提交偏小，且很好支持json格式。
```shell
docker pull mysql:5.7.26

docker images | grep mysql
#whohow20094702/mysql-5.5.5            v1.0                612ea2efcd3c        5 days ago          199MB
#mysql                                 latest              be0dbf01a0f3        2 months ago        541MB
#mysql                                 5.7.26              e9c354083de7        12 months ago       373MB

# 启动容器
docker run -itd \
--name mysql \
-p 3306:3306 \
-v ${WORKDIR}/container/mysql/my.cnf:/etc/mysql/conf.d/my.cnf \
-v $WORKDIR/container/mysql/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=root \
mysql:5.7.26

# 查看容器
docker ps | grep mysql

docker exec -it mysql sh
vi /etc/mysql/my.cnf
##--------------------------------------------------------------------
log-bin=mysql-bin # 开启binlog
binlog-format=ROW # 选择ROW模式 或 MIXED
server_id=1 # 配置MySQL replaction需要定义，不要和Canal的slaveId重复
##--------------------------------------------------------------------

# 重启
docker restart mysql

# 检查配置
docker exec -it mysql sh
> mysql -uroot -proot
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.01 sec)

mysql> show variables like 'log_bin';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | ON    |
+---------------+-------+
1 row in set (0.01 sec)

mysql> show variables like 'binlog_format';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
1 row in set (0.00 sec)

mysql> show master status;
+---------------+----------+--------------+------------------+-------------------+
| File          | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+---------------+----------+--------------+------------------+-------------------+
| binlog.000002 |      156 |              |                  |                   |
+---------------+----------+--------------+------------------+-------------------+
1 row in set (0.01 sec)
```

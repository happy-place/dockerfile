# Mysql镜像

[参考](https://github.com/tonydeng)
*注*：10.1.40-MariaDB 对应 mysql5.5 无法使用JSON。
```shell
cd WORKDIR && mkdir mysql && cd mysql 

vi my.cnf
##--------------------------------------------------------------------
[client]
#password	= your_password
port		= 3306
socket		= /mysql/run/mysql.sock

[mysqld]
user		= root
port		= 3306
socket		= /mysql/run/mysql.sock
datadir 	= /mysql/data/mysql
pid-file	= /mysql/run/mysql.pid
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M

#tmpdir		= /tmp/

#skip-networking

log-bin=mysql-bin

binlog_format=mixed

server-id	= 1
default-time-zone = '+8:00'

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
##--------------------------------------------------------------------

vi entrypoint.sh
##--------------------------------------------------------------------
#!/bin/sh
# docker entrypoint script
# configures and starts MySQL

echo "[i] Start MySQL with config /etc/mysql/my.cnf"

if [ ! -f /mysql/conf/mysql/my.cnf ]; then
    echo "[i] MySQL config file not found, copy from /etc/mysql"
    mkdir -p /mysql/conf/mysql
    cp /etc/mysql/my.cnf /mysql/conf/mysql/
fi

if [ -d /mysql/data/mysql ]; then
    echo "[i] MySQL directory already present, skipping creation"
else
    echo "[i] MySQL data directory not found, creating initial DBs"

    mkdir -p /mysql/data/mysql

    mysql_install_db --user=root > /dev/null

    if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
        MYSQL_ROOT_PASSWORD=`pwgen 16 1`
        echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
        echo $MYSQL_ROOT_PASSWORD > /mysql/conf/mysql/root_password
        echo $MYSQL_ROOT_PASSWORD > /mysql/data/mysql/root_password
    fi

    MYSQL_DATABASE=${MYSQL_DATABASE:-""}
    MYSQL_USER=${MYSQL_USER:-""}
    MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

    tfile=`mktemp`
    if [ ! -f "$tfile" ]; then
        return 1
    fi

    cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
DELETE FROM mysql.user where host!='%';
FLUSH PRIVILEGES;
EOF

    if [ "$MYSQL_DATABASE" != "" ]; then
        echo "[i] Creating database: $MYSQL_DATABASE"
        echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

        if [ "$MYSQL_USER" != "" ]; then
            echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
            echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
        fi
    fi

    /usr/bin/mysqld --init-file=$tfile --user=root --verbose=0
    rm -f $tfile
fi

# start MySQL, move to CMD in Dockerfile
# /usr/bin/mysqld --user=root --console --character-set-server=utf8

# run command passed to docker run
exec "$@"
##--------------------------------------------------------------------

vi Dockerfile
##--------------------------------------------------------------------
FROM wolfdeng/alpine:3.6

# author
MAINTAINER whohow20094702 <whohow20094702@163.com>

RUN apk update \
    && apk add --no-cache mysql mysql-client pwgen \
    && rm -rf /var/cache/apk/*

COPY my.cnf /etc/mysql/my.cnf
COPY entrypoint.sh /entrypoint.sh

EXPOSE 3306

VOLUME ["/mysql/data", "/mysql/conf", "/mysql/log", "/mysql/run"]

ENTRYPOINT ["/entrypoint.sh"]

RUN ["chmod","+x","/entrypoint.sh"]

CMD ["/usr/bin/mysqld","--defaults-file=/mysql/conf/mysql/my.cnf","--user=root","--console","--character-set-server=utf8"]
##--------------------------------------------------------------------

docker build -t mysql-5.5.5:v1.0 .

# 本地镜像映射远程仓库
docker tag mysql-5.5.5:v1.0 whohow20094702/mysql-5.5.5:v1.0

# Docker hub 创建 whohow20094702/mysql-5.5.5 仓库

# 本地镜像推送远程仓库
docker push whohow20094702/mysql-5.5.5:v1.0

# 删除本地镜像，然后尝试从远程获取
docker rmi mysql-5.5.5:v1.0 whohow20094702/mysql-5.5.5:v1.0
docker pull whohow20094702/mysql-5.5.5:v1.0

docker images | grep mysql
#whohow20094702/mysql-5.5.5  v1.0 612ea2efcd3c  7 minutes ago       199MB
#mysql                     latest be0dbf01a0f3  8 weeks ago         541MB

# 挂载到容器中充当数据目录
mkdir $WORKDIR/dockerfile/mysql/data

# 测试 java
docker run -itd --name mysql \
-p 3306:3306 \
-v $WORKDIR/dockerfile/mysql/data:/mysql/data \
-e MYSQL_DATABASE=test \
-e MYSQL_USER=test \
-e MYSQL_PASSWORD=test \
-e MYSQL_ROOT_PASSWORD=root \
whohow20094702/mysql-5.5.5:v1.0

docker exec -it mysql sh -c "mysql -utest -ptest -e 'select version()'"
+-----------------+
| version()       |
+-----------------+
| 10.1.40-MariaDB |
+-----------------+

```



# Redis镜像

## 文档

```shell
cd $WORKDIR/dockerfile && mkdir redis && cd redis 

# 如下所示
vi Dockerfile

# 如下所示
vi entrypoint.sh

docker build -t redis-5.0.9:v1.0 .

# docker hub 创建仓库 whohow20094702/redis-5.0.9

# 本地镜像映射远程仓库
docker tag redis-5.0.9:v1.0 whohow20094702/redis-5.0.9:v1.0

# 本地镜像推送远程仓库
docker push whohow20094702/redis-5.0.9:v1.0

# 删除本地镜像，然后尝试从远程获取
docker rmi redis-5.0.9:v1.0 whohow20094702/redis-5.0.9:v1.0
docker pull whohow20094702/redis-5.0.9:v1.0

docker images | grep redis
#whohow20094702/redis-5.0.9  v1.0     a95953b81fc2        About an hour ago   11.9MB
#redis                     latest     f7302e4ab3a8        11 months ago       98.2MB

mkdir $WORKDIR/dockerfile/redis/data

# 测试 redis
docker run -itd \
--name redis \
-p 6379:6379 \
-v $WORKDIR/dockerfile/redis/data:/var/lib/redis \
whohow20094702/redis-5.0.9:v1.0

docker exec -it redis sh -c 'redis-cli -r 1 -i 1 ping'
#PONG
```

## Dockerfile

```dockerfile
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
```

## entrypoint.sh

```shell
#!/bin/sh
set -e

if [[ "${1}" == "start" ]]; then
  echo "Starting Redis with defaults from /etc/redis.conf"
  exec gosu redis:redis redis-server /etc/redis.conf
elif [ "${1:0:1}" = "-" ]; then
  echo "Starting Redis with cli-set options only, no default config."
  exec gosu redis:redis redis-server $@
fi

exec "$@"
```

## gosu
[gosu下载地址](https://github.com/happy-place/dockerfile/blob/master/Redis/gosu)

*为什么要使用？*

```html
Docker容器中运行的进程，如果以root身份运行话会有安全隐患，该进程拥有容器内的全部权限，更可怕的是如果有数据卷映射到宿主机，那么通过该容器就能操作宿主机的文件夹了，一旦该容器的进程有漏洞被外部利用后果是很严重的。

因此，容器内使用非root账号运行进程才是安全的方式，这也是我们在制作镜像时要注意的地方。

而我们今天讲到的gosu 正是解决使用非root用户运行业务进程的一种最佳实践方法。

su和sudo具有非常奇怪且经常令人讨厌的TTY和信号转发行为的问题。su和sudo的设置和使用也有些复杂（特别是在sudo的情况下），虽然它们有很大的表达力，但是如果您所需要的只是“以特定用户身份运行特定应用程序”，那么它们将不再那么适合。

处理完用户/组后，我们将切换到指定用户，然后执行指定的进程，gosu本身不再驻留或完全不在进程生命周期中。这避免了信号传递和TTY的所有问题。
```
*如何使用?*

[参考](## entrypoint.sh)








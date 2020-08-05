# Kibana镜像

[参考](https://github.com/blacktop/docker-kibana-alpine)

```shell
docker build -t kibana-6.8.10:v1.0 .

# 本地镜像映射远程仓库
docker tag kibana-6.8.10:v1.0 whohow20094702/kibana-6.8.10:v1.0

# 本地镜像推送远程仓库
docker push whohow20094702/kibana-6.8.10:v1.0

# 删除本地镜像
docker rmi kibana-6.8.10:v1.0

# 尝试拉取
docker pull whohow20094702/kibana-6.8.10:v1.0

docker images | grep kibana
#whohow20094702/elasticsearch-6.8.11   v1.0     37c34656b029   3 hours ago         196MB
#nshou/elasticsearch-kibana          latest     32215d04d970   13 months ago       765MB

# 启动Elastic容器(kibana引用时ip为en0，非localhost)
docker run --init -d \
--name elastic \
-p 9200:9200 \
-v $WORKDIR/dockerfile/vol/elastic:/usr/share/elasticsearch/data \
whohow20094702/elasticsearch-6.8.11:v1.0

ifconfig | grep 'en0'
# 10.60.xxx.xxx

# 启动容器(kibana引用时ip为en0，非localhost)
docker run -itd \
--name kibana \
--link elastic \
-p 5601:5601 \
-e KIBANA_ELASTICSEARCH_URL=http://10.60.xxx.xxx:9200 \
kibana-6.8.10:v1.0

# 查看kibana启动日志
docker logs -f kibana

# 浏览器登录kibana
http://localhost:5601/
```

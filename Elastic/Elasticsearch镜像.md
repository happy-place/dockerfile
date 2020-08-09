# Elasticsearch镜像

[参考](https://github.com/blacktop/docker-elasticsearch-alpine)

```shell
# 注 jvm.options 中定义了最大最小内存(此镜像默认为126m，官方镜像为4g)
docker build -t elasticsearch-6.8.11:v1.0 .

# 本地镜像映射远程仓库
docker tag elasticsearch-6.8.11:v1.0 whohow20094702/elasticsearch-6.8.11:v1.0

# 本地镜像推送远程仓库
docker push whohow20094702/elasticsearch-6.8.11:v1.0

# 删除本地镜像
docker rmi elasticsearch-6.8.11:v1.0

# 尝试拉取
docker pull whohow20094702/elasticsearch-6.8.11:v1.0

docker images | grep elasticsearch
#whohow20094702/elasticsearch-6.8.11   v1.0     37c34656b029   3 hours ago         196MB
#nshou/elasticsearch-kibana          latest     32215d04d970   13 months ago       765MB

# 启动容器(kibana引用时ip为en0，非localhost)
docker run --init -d \
--name elastic \
-p 9200:9200 \
-v $WORKDIR/dockerfile/vol/elastic:/usr/share/elasticsearch/data \
whohow20094702/elasticsearch-6.8.11:v1.0

curl http://localhost:9200/_cat/nodes/?v
#ip         heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
#172.17.0.2           13          89   1    0.00    0.05     0.08 mdi       *      IuWGL56
```



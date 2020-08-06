# Openjdk镜像

```shell
docker build -t openjdk-1.8:v1.0 .

# 本地镜像映射远程仓库
docker tag openjdk-1.8:v1.0 whohow20094702/openjdk-1.8:v1.0

# 本地镜像推送远程仓库
docker push whohow20094702/openjdk-1.8:v1.0

# 删除本地镜像
docker rmi openjdk-1.8:v1.0

# 尝试拉取
docker pull whohow20094702/openjdk-1.8:v1.0

docker images | grep openjdk-1.8
#whohow20094702/openjdk-1.8    v1.0      0111c9cf7016        About an hour ago   91.3MB
#openjdk                     latest      0cd6de5fdbee        8 days ago          511MB

# 启动容器(kibana引用时ip为en0，非localhost)
docker run -itd \
--name jdk \
whohow20094702/openjdk-1.8:v1.0

docker exec -it jdk bash -c 'java -version'
```





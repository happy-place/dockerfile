# Bash 镜像

```shell
cd WORKDIR && mkdir bash && cd bash

vi .bashrc
## ----------------------------------------------------------------------
export HISTTIMEFORMAT="%d/%m/%y %T "
export PS1='\u@\h:\W \$ '
alias ll='ls -alF'
alias ls='ls --color=auto'
source /etc/profile.d/bash_completion.sh
## ----------------------------------------------------------------------

vi Dockerfile
## ----------------------------------------------------------------------
# using alpine-glibc instead of alpine  is mainly because JDK relies on glibc
FROM docker.io/jeanblanchard/alpine-glibc
# author
MAINTAINER whohow20094702 <whohow20094702@163.com>

# 添加bash支持
ADD .bashrc /root/
RUN set -x \
    apk update \
    && apk add --no-cache bash bash-doc bash-completion \
    && sed -i 's/ash/bash/g' /etc/passwd \
    && source /root/.bashrc

CMD ["/bin/bash"]
## ----------------------------------------------------------------------

# 构建镜像
docker build -t alpine-glibc:v1.0 .

docker images alpine-glibc:v1.0
#alpine-glibc  v1.0        36b3e8ae1ace        12 minutes ago      22.7MB

# 本地镜像映射远程仓库
docker tag alpine-glibc:v1.0 whohow20094702/alpine-glibc:v1.0

# 本地镜像推送远程仓库
docker push whohow20094702/alpine-glibc:v1.0

# 删除本地镜像
docker rmi alpine-glibc:v1.0 whohow20094702/alpine-glibc:v1.0

docker images | grep alpine-glibc
#whohow20094702/alpine-glibc  v1.0  36b3e8ae1ace 25 minutes ago    22.7MB
#jeanblanchard/alpine-glibc  latest b18af330677b  2 months ago     17.3MB
```




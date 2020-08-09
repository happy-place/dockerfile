# using alpine-glibc instead of alpine  is mainly because JDK relies on glibc
FROM docker.io/jeanblanchard/alpine-glibc
# author
MAINTAINER whohow20094702 <whohow20094702@163.com>

ADD .bashrc /root/
RUN set -x \
    apk update \
    && apk add --no-cache bash bash-doc bash-completion \
    && sed -i 's/ash/bash/g' /etc/passwd \
    && source /root/.bashrc

CMD ["/bin/bash"]


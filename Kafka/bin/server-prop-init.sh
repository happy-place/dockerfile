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

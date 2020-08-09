#!/bin/bash

ELASTIC=http://localhost:9200
CURL="curl -u user:pass"

case $1 in
    del_index)
        echo "$CURL -XDELETE $ELASTIC/$2 | jq"
        bash -c "$CURL -XDELETE $ELASTIC/$2 | jq"
        ;;
        mapping)
                echo "$CURL -XGET $ELASTIC/$2/_mapping | jq"
        bash -c "$CURL -XGET $ELASTIC/$2/_mapping | jq"
        ;;
        select)
                echo "$CURL -XGET $ELASTIC/$2/_search?q=$3 | jq"
                bash -c "$CURL -XGET $ELASTIC/$2/_search?q=$3 | jq"
        ;;
        insert)
                echo "$CURL -XPOST "$ELASTIC/$2/_doc/$3" -H 'Content-Type: application/json' -d '$4' | jq"
                bash -c "$CURL -XPOST "$ELASTIC/$2/_doc/$3" -H 'Content-Type: application/json' -d '$4' | jq"
        ;;
        update)
                echo "$CURL -XPUT "$ELASTIC/$2/_doc/$3" -H 'Content-Type: application/json' -d '$4' | jq"
                bash -c "$CURL -XPUT "$ELASTIC/$2/_doc/$3" -H 'Content-Type: application/json' -d '$4' | jq"
        ;;
        delete)
                echo "$CURL -XDELETE "$ELASTIC/$2/_doc/$3" | jq"
                bash -c "$CURL -XDELETE "$ELASTIC/$2/_doc/$3" | jq"
        ;;
        *)
                echo '删除索引: elastic del_index $index'
                echo '查看映射: elastic mapping $index'
                echo '查找记录(name:tom): elastic select $index $where'
                echo '新增记录: elastic insert $index $id $doc'
                echo '修改记录: elastic update $index $id $doc'
                echo '删除记录: elastic delete $index $id'
        ;;
esac

exit 0

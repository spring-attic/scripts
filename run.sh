#!/bin/bash

set -e

mkdir -p target/logs

for p in 8081 9000 8888 8761 9900; do
    netstat -tlnp | cut --b 21-41 | grep $p && used=$used","$p
done
[ "$used" != "" ] && echo Ports ${used#,} in use, please kill the 'process(es)' and try again && exit 1

function run_app() {

    NAME=$1
    PREFIX=
    APP=${1}App
    [ "$1" == "stores" ] && APP=StoreApp && NAME=store && PREFIX=customers-stores/rest-microservices-
    [ "$1" == "customers" ] && APP=CustomerApp && PREFIX=customers-stores/rest-microservices-
    DIR=$PREFIX$NAME
    if jps | grep -i ${APP} > /dev/null; then
        echo "$1 already running"
        exit 1
    fi
    if [ -f $DIR/.settings.xml ]; then 
        SETTINGS='--settings .settings.xml'
    fi
    TMPHOME=`pwd`
    (cd $DIR; mvn $SETTINGS spring-boot:run > "${TMPHOME}"/target/logs/$1.log &)
    echo "Launching $1 (logs in target/logs/$1.log)"

}

apps=$*
if [ -z $1 ]; then
    apps='configserver eureka customers stores'
fi
for f in $apps; do
    run_app $f
done




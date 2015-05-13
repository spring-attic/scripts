#!/bin/bash

set -e

mkdir -p target/logs

ports[configserver]=8888
ports[eureka]=8761
ports[customers]=9000
ports[stores]=8081
ports[customersui]=9900

function check_port() {
    p=${ports[$1]}
    netstat -tlnp 2>&1 | cut --b 21-41 | grep $p && used=$p
    if [ "$used" != "" ]; then
        echo Port ${used} in use for app $1, please kill the 'process' and try again
        exit 1
    fi
}

function run_app() {

    NAME=$1
    PREFIX=
    [ "$1" == "stores" ] && NAME=store && PREFIX=customers-stores/rest-microservices-
    [ "$1" == "customers" ] && PREFIX=customers-stores/rest-microservices-
    [ "$1" == "customersui" ] && NAME=customers-stores-ui && PREFIX=customers-stores/
    check_port $NAME
    DIR=$PREFIX$NAME
    if [ -f $DIR/.settings.xml ]; then 
        SETTINGS='--settings .settings.xml'
    fi
    TMPHOME=`pwd`
    cmd="mvn $SETTINGS spring-boot:run"
    if [ "$1" == "customersui" ]; then
        cmd="spring run app.groovy"
    fi
    (cd $DIR; $cmd > "${TMPHOME}"/target/logs/$1.log &)
    echo "Launching $1 (logs in target/logs/$1.log)"

}

apps=$*
if [ -z $1 ]; then
    apps='configserver eureka customers stores customersui'
fi
for f in $apps; do
    run_app $f
done




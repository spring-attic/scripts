#!/bin/bash

set -e

function kill_app() {
    NAME=$1
    PREFIX=
    APP=${1}Application
    [ "$1" == "stores" ] && APP=StoreApp
    [ "$1" == "customers" ] && APP=CustomerApp
    PID=`jps | grep -i ${APP} | sed -e 's/^\([0-9]*\).*/\1/'`
    [ "$PID" == "" ] || kill -9 $PID
}

apps=$*
if [ -z $1 ]; then
    apps='configserver eureka customers stores'
fi
for f in $apps; do
    kill_app $f
done




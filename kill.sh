#!/bin/bash

set -e

function kill_app() {
    NAME=$1
    PREFIX=
    APP=${1}Application
    [ "$1" == "customersui" ] && APP=app.groovy || APP="spring-boot:run"
    PID=`jps -mlv | grep -i ${APP} | sed -e 's/^\([0-9]*\).*/\1/'`
    [ "$PID" == "" ] || kill $PID
}

apps=$*
if [ -z $1 ]; then
    apps='configserver eureka customers stores customersui'
fi
for f in $apps; do
    kill_app $f
done




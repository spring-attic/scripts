#!/bin/bash

# set -x

DOMAIN=${DOMAIN:-run.pivotal.io}
TARGET=api.${DOMAIN}
APPLICATION_DOMAIN=${APPLICATION_DOMAIN:-"$DOMAIN"}
if [ "$DOMAIN" == "run.pivotal.io" ]; then
    APPLICATION_DOMAIN=cfapps.io
fi
if [ "$PREFIX" == "NONE" ]; then 
    PREFIX=
elif [ "$PREFIX" == "" ]; then
    PREFIX=$USER
fi

cf api | grep ${TARGET} || cf api ${TARGET} --skip-ssl-validation
cf apps | grep OK || cf login

function delete_broker() {
    line=`cf services | grep ^$1 | sed -e 's/ \+/:/g' -e 's/,:/,/g'`
    field=4
    echo $line | grep 'user-provided' && field=3 # no plan
    for f in `echo $line | cut -d ':' -f 1,$field`; do
        APPS=${f#*:}
        if [ "$APPS" != "$f" ]; then
            SERVICE=${f%:*}
            for APP in `echo $APPS | sed -e 's/,/ /g'`; do
                cf unbind-service $APP $SERVICE
            done
        fi
    done
    cf delete-service -f $1
    cf apps | grep ^$1 && cf delete -f $1
}

apps=$*
if [ -z $1 ]; then
    apps='eureka configserver mongodb rabbitmq'
fi

for f in $apps; do
    delete_broker $PREFIX$f
done




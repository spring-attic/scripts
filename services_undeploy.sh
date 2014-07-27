#!/bin/bash

# set -x

DOMAIN=${DOMAIN:-184.72.224.23.xip.io}
TARGET=api.${DOMAIN}
if [ "$PREFIX" == "NONE" ]; then 
    PREFIX=
else 
    PREFIX=$USER
fi

cf api | grep ${TARGET} || cf api ${TARGET} --skip-ssl-validation
cf apps || cf login

function delete_broker() {
    for f in `cf services | grep $1 | sed -e 's/ \+/:/g' -e 's/,:/,/g' | cut -d ':' -f 1,4`; do
        APPS=${f#*:}
        if [ $APPS != $f ]; then
            SERVICE=${f%:*}
            for APP in `echo $APPS | sed -e 's/,/ /g'`; do
                cf unbind-service $APP $SERVICE
            done
        fi
    done
    cf delete-service -f $1
    cf apps | grep $1 && cf delete -f $1
}

apps=$*
if [ -z $1 ]; then
    apps='configserver eureka mongodb'
fi

for f in $apps; do
    delete_broker $PREFIX$f
done




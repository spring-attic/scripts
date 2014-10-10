#!/bin/bash

set -e

DOMAIN=${DOMAIN:-run.pivotal.io}
TARGET=api.${DOMAIN}
APPLICATION_DOMAIN=${APPLICATION_DOMAIN:-"$DOMAIN"}
if [ "$DOMAIN" == "run.pivotal.io" ]; then
    APPLICATION_DOMAIN=cfapps.io
fi

cf api | grep ${TARGET} || cf api ${TARGET} --skip-ssl-validation
cf apps | grep OK || cf login

TMPHOME=$(cd `dirname "$0"` && pwd)
if [ "$PREFIX" == "NONE" ]; then 
    PREFIX=
elif [ "$PREFIX" == "" ]; then 
    PREFIX=$USER
fi

PLATFORM_HOME=${PLATFORM_HOME:-$TMPHOME}
echo Home: $PLATFORM_HOME

DEMO_HOME=${DEMO_HOME:-$PLATFORM_HOME/customers-stores}
# TODO: clone and build

function undeploy_app() {

    APP=$PREFIX$1
    cf delete -f $APP

}

apps=$*
if [ -z $1 ]; then
    apps='stores customers customersui hystrix-dashboard turbine'
fi
for f in $apps; do
    undeploy_app $f
done

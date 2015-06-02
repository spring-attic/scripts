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

function find_jar() {
    if [ -d $1 ]; then
        ls $1/*.jar | egrep -v 'javadoc|sources'
    else
        echo $1/app.jar
    fi
}

function deploy_app() {

    APP=$PREFIX$1
    NAME=$1
    [ "$1" == "stores" ] && NAME=store
    JARPATH=$(find_jar "$DEMO_HOME/rest-microservices-$NAME/target")
    [ "$1" == "customersui" ] && JARPATH=$DEMO_HOME/customers-stores-ui/app.jar
    [ "$1" == "hystrix-dashboard" -o "$1" == "turbine" ] && JARPATH=$(find_jar "$PLATFORM_HOME/$NAME/target")

    if ! [ -f "$JARPATH" ]; then
        echo "No jar for deployment of $1 at: $JARPATH"
        exit 0
    fi

    cf push $APP -m 1028m -p $JARPATH --no-start
    cf env $APP | grep SPRING_PROFILES_ACTIVE || cf set-env $APP SPRING_PROFILES_ACTIVE cloud
    cf env $APP | grep ENCRYPT_KEY || cf set-env $APP ENCRYPT_KEY deadbeef
    if [ "$PREFIX" != "" ]; then
        cf env $APP | grep PREFIX || cf set-env $APP PREFIX $PREFIX
    fi
    if [ "$APPLICATION_DOMAIN" != "cfapps.io" ]; then
        cf set-env $APP APPLICATION_DOMAIN $APPLICATION_DOMAIN
    else
        cf set-env $APP DOMAIN $APPLICATION_DOMAIN        
    fi

    cf bind-service $APP ${PREFIX}configserver
    cf bind-service $APP ${PREFIX}eureka
    cf bind-service $APP ${PREFIX}rabbitmq
    [ "$1" == "stores" ] &&  cf bind-service $APP ${PREFIX}mongodb
    
    cf restart $APP

}

apps=$*
if [ -z $1 ]; then
    apps='stores customers customersui hystrix-dashboard turbine'
fi
for f in $apps; do
    deploy_app $f
done

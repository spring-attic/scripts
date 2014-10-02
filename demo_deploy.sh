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
else 
    PREFIX=$USER
fi

PLATFORM_HOME=${PLATFORM_HOME:-$TMPHOME}
echo Home: $PLATFORM_HOME

DEMO_HOME=${DEMO_HOME:-$PLATFORM_HOME/customers-stores}
# TODO: clone and build

function deploy_app() {

    APP=$PREFIX$1
    NAME=$1
    [ "$1" == "stores" ] && NAME=store
    JARPATH=$DEMO_HOME/rest-microservices-$NAME/target/*.jar
    [ "$1" == "customersui" ] && JARPATH=$DEMO_HOME/customers-stores-ui/app.jar
    [ "$1" == "hystrix-dashboard" -o "$1" == "turbine" ] && JARPATH=$PLATFORM_HOME/$NAME/target/*.jar

    #TODO: using java8 because of temp requirement for spring-platform-bus
    cf push $APP -m 1028m -b https://github.com/spring-io/java-buildpack -p $JARPATH --no-start
    cf env $APP | grep SPRING_PROFILES_ACTIVE || cf set-env $APP SPRING_PROFILES_ACTIVE cloud
    if [ "$PREFIX" != "" ]; then
        cf env $APP | grep PREFIX || cf set-env $APP PREFIX $PREFIX
    fi
    [ "$APPLICATION_DOMAIN" != "cfapps.io" ] && cf set-env $APP APPLICATION_DOMAIN $APPLICATION_DOMAIN

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

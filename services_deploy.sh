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
    echo setting PREFIX to empty
    PREFIX=
    echo PREFIX = $PREFIX
else 
    PREFIX=$USER
fi

PLATFORM_HOME=${PLATFORM_HOME:-$TMPHOME}
echo Home: $PLATFORM_HOME

CONFIG_HOME=${CONFIG_HOME:-$PLATFORM_HOME/configserver}

EUREKA_HOME=${EUREKA_HOME:-$PLATFORM_HOME/eureka}

function deploy() {

    APP=$PREFIX$1
    APP_HOME=$2

    cf push $APP -m 512m -p $APP_HOME/target/*.jar --no-start
    cf env $APP | grep SPRING_PROFILES_ACTIVE || cf set-env $APP SPRING_PROFILES_ACTIVE cloud
    if [ "$PREIX" != "" ]; then
        cf env $APP | grep PREFIX || cf set-env $APP PREFIX $PREFIX
    fi
    if [ "$1" == "configserver" ]; then
        cf env $APP | grep APPLICATION_DOMAIN || cf set-env $APP APPLICATION_DOMAIN $APPLICATION_DOMAIN
    else
        cf services | grep ^${PREFIX}configserver && cf bind-service $APP ${PREFIX}configserver
    fi
    
    cf restart $APP
    # TODO push this to server
    cf services | grep ^$APP || cf create-user-provided-service $APP -p '{"uri":"http://'$APP.$APPLICATION_DOMAIN'"}'

}

apps=$*
if [ -z $1 ]; then
    apps='configserver eureka mongodb'
fi

for f in $apps; do
    h=.
    if [ $f == "configserver" ]; then
        h=$CONFIG_HOME
    elif [ $f == "eureka" ]; then
        h=$EUREKA_HOME
    elif [ $f == "mongodb" ]; then
        if ! [ "$MONGO_URI" == "" ]; then
            cf services | grep ^${PREFIX}mongodb || cf create-user-provided-service ${PREFIX}mongodb -p '{"uri":"'$MONGO_URI'"}'
            exit 0
        elif cf marketplace | grep mongolab; then
            cf services | grep ^${PREFIX}mongodb || cf create-service mongolab sandbox ${PREFIX}mongodb
            exit 0
        # for https://github.com/cloudfoundry-community/cf-services-contrib-release dev services
        elif cf marketplace | grep mongodb; then
            cf services | grep ^${PREFIX}mongodb || cf create-service mongodb default ${PREFIX}mongodb
            exit 0
        else
            echo "MONGO_URI not set and no mongolab or mongodb service available. Please set up MONGO_URI to point to globally accessible mongo instance."
            exit 1
        fi
    fi
    deploy $f $h
done


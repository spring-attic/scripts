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
elif [ "$PREFIX" == "" ]; then
    PREFIX=$USER
fi

PLATFORM_HOME=${PLATFORM_HOME:-$TMPHOME}
echo Home: $PLATFORM_HOME

CONFIG_HOME=${CONFIG_HOME:-$PLATFORM_HOME/configserver}

EUREKA_HOME=${EUREKA_HOME:-$PLATFORM_HOME/eureka}

function find_jar() {
    if [ -d $1 ]; then
        ls $1/*.jar | egrep -v 'javadoc|sources'
    else
        echo $1/app.jar
    fi
}

function deploy() {

    APP=$PREFIX$1
    APP_HOME=$2

    JARPATH=$(find_jar "$APP_HOME/target")
    cf push $APP -m 512m -p "$JARPATH" --no-start
    cf env $APP | grep SPRING_PROFILES_ACTIVE || cf set-env $APP SPRING_PROFILES_ACTIVE cloud
    cf env $APP | grep ENCRYPT_KEY || cf set-env $APP ENCRYPT_KEY deadbeef
    if [ "$PREFIX" != "" ]; then
        cf env $APP | grep PREFIX || cf set-env $APP PREFIX $PREFIX
    fi
    if [ "$1" == "configserver" ]; then
        cf env $APP | grep APPLICATION_DOMAIN || cf set-env $APP APPLICATION_DOMAIN $APPLICATION_DOMAIN
        cf env $APP | grep KEYSTORE_PASSWORD || cf set-env $APP KEYSTORE_PASSWORD foobar
    else
        cf services | grep ^${PREFIX}configserver && cf bind-service $APP ${PREFIX}configserver
    fi
    
    cf restart $APP
    # TODO push this to server
    cf services | grep ^$APP || cf create-user-provided-service $APP -p '{"uri":"http://user:password@'$APP.$APPLICATION_DOMAIN'"}'

}

apps=$*
if [ -z $1 ]; then
    apps='rabbitmq mongodb configserver eureka'
fi

for f in $apps; do
    h=.
    if [ $f == "configserver" ]; then
        h=$CONFIG_HOME
    elif [ $f == "eureka" ]; then
        h=$EUREKA_HOME
    elif [ $f == "rabbitmq" ]; then
        if ! [ "$RABBIT_URI" == "" ]; then
            cf services | grep ^${PREFIX}rabbitmq || cf create-user-provided-service ${PREFIX}rabbitmq -p '{"uri":"'$RABBIT_URI'"}'
            continue
        elif cf marketplace | grep cloudamqp; then
            cf services | grep ^${PREFIX}rabbitmq || cf create-service cloudamqp tiger ${PREFIX}rabbitmq
            continue
        elif cf marketplace | grep p-rabbitmq; then
            cf services | grep ^${PREFIX}rabbitmq || cf create-service p-rabbitmq standard ${PREFIX}rabbitmq
            continue
        else
            echo "no rabbitmq service available."
            exit 1
        fi
    elif [ $f == "mongodb" ]; then
        if ! [ "$MONGO_URI" == "" ]; then
            cf services | grep ^${PREFIX}mongodb || cf create-user-provided-service ${PREFIX}mongodb -p '{"uri":"'$MONGO_URI'"}'
            continue
        elif cf marketplace | grep p-mongodb; then
            cf services | grep ^${PREFIX}mongodb || cf create-service p-mongodb development ${PREFIX}mongodb
            continue
        elif cf marketplace | grep mongolab; then
            cf services | grep ^${PREFIX}mongodb || cf create-service mongolab sandbox ${PREFIX}mongodb
            continue
        # for https://github.com/cloudfoundry-community/cf-services-contrib-release dev services
        elif cf marketplace | grep mongodb; then
            cf services | grep ^${PREFIX}mongodb || cf create-service mongodb default ${PREFIX}mongodb
            continue
        else
            echo "MONGO_URI not set and no mongolab or mongodb service available. Please set up MONGO_URI to point to globally accessible mongo instance."
            exit 1
        fi
    fi
    deploy $f $h
done


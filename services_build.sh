#!/bin/bash

set -e

TMPHOME=$(cd `dirname "$0"`/.. && pwd)

PLATFORM_HOME=${PLATFORM_HOME:-$TMPHOME}
echo Home: $PLATFORM_HOME

CLOUDFOUNDRY_HOME=${CLOUDFOUNDRY_HOME:-$PLATFORM_HOME/cloudfoundry}
# TODO: clone and build

CONFIG_SERVER_HOME=${CONFIG_SERVER_HOME:-$PLATFORM_HOME/config}
# TODO: clone and build

CONFIG_HOME=${CONFIG_HOME:-$PLATFORM_HOME/workspace/configserver}
# TODO: clone and build

EUREKA_HOME=${EUREKA_HOME:-$PLATFORM_HOME/workspace/eureka-broker}
# TODO: clone and build

CF_BROKER_HOME=${CF_BROKER_HOME:-$PLATFORM_HOME/spring-boot-cf-service-broker}
# TODO: clone and build

for f in $CF_BROKER_HOME $CONFIG_SERVER_HOME $CLOUDFOUNDRY_HOME $EUREKA_HOME $CONFIG_HOME; do
  (cd $f; mvn clean install -DskipTests)
done

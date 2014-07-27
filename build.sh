#!/bin/bash

set -e

TMPHOME=$(cd `dirname "$0"` && pwd)

PLATFORM_HOME=${PLATFORM_HOME:-$TMPHOME}
echo Home: $PLATFORM_HOME

for f in */pom.xml; do
  (cd ${f%*/pom.xml}; mvn clean install -DskipTests)
done

#!/bin/bash

set -ex

git submodule update --init
git submodule foreach '(git checkout master && git pull --rebase) || echo "Not attempting to sync"'
if [ ".$@" == "." ]; then
    mvn --settings config/.settings.xml clean install -P build,!base,!starters,!apps -DskipTests
    mvn --settings config/.settings.xml clean install -P !build,!base,starters,!apps -DskipTests
fi
mvn --settings config/.settings.xml clean install "$@" -DskipTests

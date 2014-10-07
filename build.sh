#!/bin/bash

set -e

git submodule update --init
git submodule foreach '(git checkout master && git pull --rebase) || echo "Not attempting to sync"'
mvn --settings config/.settings.xml clean install "$@"

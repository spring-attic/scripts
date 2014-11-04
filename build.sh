#!/bin/bash

set -e

git submodule update --init
git submodule foreach '(git checkout 1.0.0.M2 && git pull --rebase) || echo "Not attempting to sync"'
mvn --settings config/.settings.xml clean install "$@"

#!/bin/bash

set -e

ROOT_FOLDER=$(pwd)
RELEASE_TRAIN_PROJECTS=${RELEASE_TRAIN_PROJECTS:-build commons function stream-core stream-binder-rabbit stream-binder-kafka bus task config netflix cloudfoundry kubernetes openfeign consul gateway security sleuth zookeeper contract vault circuitbreaker cli}

echo "Current folder is [${ROOT_FOLDER}]"
ARTIFACTS=( ${RELEASE_TRAIN_PROJECTS} )

for i in "${ARTIFACTS[@]}"; do
    pushd "${i}"
      echo "Updating [${i}]"
#       git reset --hard || echo "Failed to reset"
       git checkout master || echo "Failed to checkout master"
#      git add docs/pom.xml || echo "Failed to add docs"
#      git commit -m "Setting up repository for docs.spring.io migration" || echo "Nothing to commit"
#      git pull --rebase
#      git push origin master || echo "Nothing to push"
       echo "You can do sth here"
    popd
done
#!/bin/bash

# If you have exceptions while using associative arrays from Bash 4.0 in OSX.
# instead of #!/bin/bash you have to have #!/usr/local/bin/bash

set -e

ROOT_FOLDER=$(pwd)
RELEASE_TRAIN_PROJECTS=${RELEASE_TRAIN_PROJECTS:-build commons function stream bus task config netflix cloudfoundry kubernetes openfeign consul gateway security sleuth zookeeper contract vault circuitbreaker cli}
GIT_BIN="${GIT_BIN:-git}"

echo "Current folder is [${ROOT_FOLDER}]"
ARTIFACTS=( ${RELEASE_TRAIN_PROJECTS} )

for i in "${ARTIFACTS[@]}"; do
    pushd "${i}"
      echo "Updating master branch for [${i}]"
      git reset --hard || echo "Failed to reset"
      git checkout master || echo "Failed to checkout master"
      git pull --rebase
      echo "You can do sth by changing this line"
    popd
done
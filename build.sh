#!/bin/bash

set -e

git submodule update --init
mvn clean install

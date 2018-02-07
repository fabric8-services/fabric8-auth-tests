#!/bin/bash

source _setenv.sh

echo " Prepare environment"
./prepare.sh

echo "Build WIT server"
./build.sh

echo "Run tests"
./test.sh

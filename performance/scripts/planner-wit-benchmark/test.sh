#!/bin/bash

source _setenv.sh

cd $GOPATH/src/github.com/fabric8-services/fabric8-wit

docker-compose down
docker-compose up -d
make test-integration-benchmark 2>$WORKSPACE/test-error.log 1>$WORKSPACE/test.log

cat $WORKSPACE/test.log | grep "ns/op" | sed -e 's,[ ]*\t\+[ ]*,;,g' | sed -e 's, ,;,g' > $WORKSPACE/test-results.csv


#!/bin/bash

#source _setenv.sh

LOCUST_FILE=${1:-osioperf.py}

if [ -f $LOCUST_FILE ]; then
	CMD="nohup locust -f $LOCUST_FILE --no-web --print-stats --no-reset-stats --clients=$USERS --hatch-rate=$USER_HATCH_RATE --csv=$JOB_BASE_NAME-$BUILD_NUMBER-report 2>$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log > $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log &";
	echo "Starting a Locust: $CMD";
	echo $CMD >> $$-master;
	source $ENV_FILE-master; bash -s < $$-master;
	rm -rf $$-master;
else
	echo "$LOCUST_FILE not found";
	exit 1;
fi



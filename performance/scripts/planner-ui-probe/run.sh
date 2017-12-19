#!/bin/bash

source _setenv.sh

echo " Wait for the server to become available"
./_wait-for-server.sh
if [ $? -gt 0 ]; then
	exit 1
fi

mvn clean compile
MVN_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-mvn.log
mvn -l $MVN_LOG exec:java -Dserver.host=$SERVER_SCHEME://$SERVER_HOST -Dserver.port=$SERVER_PORT -Diterations=$ITERATIONS
PLANNER_UI_PROBE_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-planner-ui-probe.log
cat $MVN_LOG | grep planner-ui-probe > $PLANNER_UI_PROBE_LOG

echo " Prepare results for Zabbix"
rm -rvf *-zabbix.log
./_zabbix-process-results.sh $PLANNER_UI_PROBE_LOG

ZABBIX_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-zabbix.log
cat $ZABBIX_LOG
if [[ "$ZABBIX_REPORT_ENABLED" = "true" ]]; then
	echo "  Uploading report to zabbix...";
	zabbix_sender -vv -i $ZABBIX_LOG -T -z $ZABBIX_SERVER -p $ZABBIX_PORT;
fi

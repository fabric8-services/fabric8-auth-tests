#!/bin/bash

source _setenv.sh

echo " Prepare environment"
./_prepare.sh

echo " Build WIT server"
./_build.sh

echo " Run tests"
./_test.sh

echo " Prepare Zabbix report"
export ZABBIX_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-zabbix.log
./_zabbix.sh $JOB_BASE_NAME-$BUILD_NUMBER-results.csv $ZABBIX_LOG

if [[ "$ZABBIX_REPORT_ENABLED" = "true" ]]; then
	echo "  Uploading report to zabbix...";
	zabbix_sender -vv -i $ZABBIX_LOG -T -z $ZABBIX_SERVER -p $ZABBIX_PORT;
fi


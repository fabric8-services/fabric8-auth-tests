#!/bin/bash

source _setenv.sh

if [ ! -f "$1" ]; then
	echo "File '$1' not found! Skipping Zabbix reporting... !!!"
	exit 0
fi

PLANNER_UI_PROBE_LOG=$1
TIMESTAMP=`date +%s`
ZABBIX_LOG_FILE=$JOB_BASE_NAME-$BUILD_NUMBER-zabbix.log

for m in "open-login-page" "login" "user-menu" "load-planner" "logout"; do
	TIME_STATS=(`cat $PLANNER_UI_PROBE_LOG | grep "$m-time-stats" | sed -e 's,.*stats:\(.*\),\1,g' | tr ';' ' '`)
	echo -n "$ZABBIX_HOST $m-time.min $TIMESTAMP " >> $ZABBIX_LOG_FILE
	echo ${TIME_STATS[1]} | cut -d "=" -f 2 >> $ZABBIX_LOG_FILE
	echo -n "$ZABBIX_HOST $m-time.median $TIMESTAMP " >> $ZABBIX_LOG_FILE
	echo ${TIME_STATS[2]} | cut -d "=" -f 2 >> $ZABBIX_LOG_FILE
	echo -n "$ZABBIX_HOST $m-time.max $TIMESTAMP " >> $ZABBIX_LOG_FILE
	echo ${TIME_STATS[3]} | cut -d "=" -f 2 >> $ZABBIX_LOG_FILE
done;
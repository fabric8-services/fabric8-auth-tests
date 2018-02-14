#!/bin/bash

source _setenv.sh

export ZABBIX_LOG=$1
export ZABBIX_TIMESTAMP=`date +%s`

./__zabbix-process-login.sh >> $ZABBIX_LOG

./__zabbix-process-load.sh '"GET","auth-api-user"' "auth-api-user" >> $ZABBIX_LOG
./__zabbix-process-load.sh '"GET","auth-api-user-github-token"' "auth-api-user-github-token" >> $ZABBIX_LOG
./__zabbix-process-load.sh '"POST","auth-api-token-refresh"' "auth-api-token-refresh" >> $ZABBIX_LOG
./__zabbix-process-load.sh '"GET","api-user-by-id"' "api-user-by-id" >> $ZABBIX_LOG
./__zabbix-process-load.sh '"GET","api-user-by-name"' "api-user-by-name" >> $ZABBIX_LOG
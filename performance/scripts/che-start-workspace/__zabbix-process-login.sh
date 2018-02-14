#!/bin/bash

source _setenv.sh

ZABBIX_LOG=${1:-$JOB_BASE_NAME-$BUILD_NUMBER-zabbix.log}

if [ -z $ZABBIX_TIMESTAMP ]; then
  export ZABBIX_TIMESTAMP=`date +%s`;
fi

# Auth login
LOGIN_USERS_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-login-users.log
OPEN_LOGIN_PAGE_TIME_STATS=(`cat $LOGIN_USERS_LOG | grep "open-login-page-time-stats" | sed -e 's,.*stats:\(.*\),\1,g' | tr ';' ' '`)
LOGIN_TIME_STATS=(`cat $LOGIN_USERS_LOG | grep "login-time-stats" | sed -e 's,.*stats:\(.*\),\1,g' | tr ';' ' '`)

echo -n "$ZABBIX_HOST open-login-page-time.min $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${OPEN_LOGIN_PAGE_TIME_STATS[1]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST open-login-page-time.median $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${OPEN_LOGIN_PAGE_TIME_STATS[2]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST open-login-page-time.max $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${OPEN_LOGIN_PAGE_TIME_STATS[3]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST login-time.min $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${LOGIN_TIME_STATS[1]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST login-time.median $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${LOGIN_TIME_STATS[2]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST login-time.max $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${LOGIN_TIME_STATS[3]} | cut -d "=" -f 2 >> $ZABBIX_LOG

#Oauth2 Login
LOGIN_USERS_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-login-users-oauth2.log
OPEN_LOGIN_PAGE_TIME_STATS=(`cat $LOGIN_USERS_LOG | grep "open-login-page-time-stats" | sed -e 's,.*stats:\(.*\),\1,g' | tr ';' ' '`)
GET_CODE_TIME_STATS=(`cat $LOGIN_USERS_LOG | grep "get-code-time-stats" | sed -e 's,.*stats:\(.*\),\1,g' | tr ';' ' '`)
GET_TOKEN_TIME_STATS=(`cat $LOGIN_USERS_LOG | grep "get-token-time-stats" | sed -e 's,.*stats:\(.*\),\1,g' | tr ';' ' '`)
LOGIN_TIME_STATS=(`cat $LOGIN_USERS_LOG | grep "login-time-stats" | sed -e 's,.*stats:\(.*\),\1,g' | tr ';' ' '`)

echo -n "$ZABBIX_HOST oauth2.open-login-page-time.min $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${OPEN_LOGIN_PAGE_TIME_STATS[1]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.open-login-page-time.median $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${OPEN_LOGIN_PAGE_TIME_STATS[2]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.open-login-page-time.max $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${OPEN_LOGIN_PAGE_TIME_STATS[3]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.get-code-time.min $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${GET_CODE_TIME_STATS[1]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.get-code-time.median $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${GET_CODE_TIME_STATS[2]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.get-code-time.max $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${GET_CODE_TIME_STATS[3]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.get-token-time.min $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${GET_TOKEN_TIME_STATS[1]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.get-token-time.median $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${GET_TOKEN_TIME_STATS[2]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.get-token-time.max $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${GET_TOKEN_TIME_STATS[3]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.login-time.min $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${LOGIN_TIME_STATS[1]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.login-time.median $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${LOGIN_TIME_STATS[2]} | cut -d "=" -f 2 >> $ZABBIX_LOG

echo -n "$ZABBIX_HOST oauth2.login-time.max $ZABBIX_TIMESTAMP " >> $ZABBIX_LOG
echo ${LOGIN_TIME_STATS[3]} | cut -d "=" -f 2 >> $ZABBIX_LOG

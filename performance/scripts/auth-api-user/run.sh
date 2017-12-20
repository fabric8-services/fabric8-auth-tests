#!/bin/bash

source _setenv.sh

export COMMON="../_common"

echo " Wait for the server to become available"
./_wait-for-server.sh
if [ $? -gt 0 ]; then
	exit 1
fi

echo " Login users and get auth tokens"
LOGIN_USERS=$COMMON/loginusers

mvn -f $LOGIN_USERS/pom.xml clean compile
cat $USERS_PROPERTIES_FILE > $LOGIN_USERS/target/classes/users.properties
export TOKENS_FILE=`readlink -f /tmp/osioperftest.tokens`
MVN_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-mvn.log
mvn -f $LOGIN_USERS/pom.xml -l $MVN_LOG exec:java -Dauth.server.address=$SERVER_SCHEME://$SERVER_HOST -Dauth.server.port=$AUTH_PORT -Duser.tokens.file=$TOKENS_FILE
LOGIN_USERS_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-login-users.log
cat $MVN_LOG | grep login-users-log > $LOGIN_USERS_LOG

	echo "#!/bin/bash
export USER_TOKENS=\"0;0\"
" > $ENV_FILE-master;

TOKEN_COUNT=`cat $TOKENS_FILE | wc -l`
i=1
s=1
rm -rf $TOKENS_FILE-slave-*;
while [ $i -le $TOKEN_COUNT ]; do
	sed "${i}q;d" $TOKENS_FILE >> $TOKENS_FILE-slave-$s;
	i=$((i+1));
	if [ $s -lt $SLAVES ]; then
		s=$((s+1));
	else
		s=1;
	fi;
done

for s in $(seq 1 $SLAVES); do
	echo "#!/bin/bash
export USER_TOKENS=\"$(cat $TOKENS_FILE-slave-$s)\"
" > $ENV_FILE-slave-$s;
done

echo " Prepare locustfile template"
./_prepare-locustfile.sh auth-api-user.py

echo " Shut Locust master down"
$COMMON/__stop-locust-master.sh

echo " Shut Locust slaves down"
SLAVES=10 $COMMON/__stop-locust-slaves.sh

echo " Start Locust master waiting for slaves"
$COMMON/__start-locust-master.sh

echo " Start all the Locust slaves"
$COMMON/__start-locust-slaves.sh

echo " Run test for $DURATION seconds"
sleep $DURATION

echo " Shut Locust master down"
$COMMON/__stop-locust-master.sh TERM

echo " Download locust reports from Locust master"
$COMMON/_gather-locust-reports.sh

echo " Extract CSV data from logs"
$COMMON/_locust-log-to-csv.sh 'GET auth-api-user ' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'GET auth-api-user-github-token' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'POST auth-api-token-refresh' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'GET api-user-by-id' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'GET api-user-by-name' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log

echo " Generate charts from CSV"
export REPORT_CHART_WIDTH=1000
export REPORT_CHART_HEIGHT=600
for c in $(find *.csv | grep '\-POST_\+\|\-GET_\+'); do echo $c; $COMMON/_csv-response-time-to-png.sh $c; $COMMON/_csv-throughput-to-png.sh $c; $COMMON/_csv-failures-to-png.sh $c; done
for c in $(find *.csv | grep '_distribution.csv'); do echo $c; $COMMON/_csv-rt-histogram-to-png.sh $c; done

cat $JOB_BASE_NAME-$BUILD_NUMBER-login-users.log | grep 'open-login-page:' | sed -e 's,\(.*\) INFO.*:\([0-9]\+\)ms.*,\1;\2,g' > $JOB_BASE_NAME-$BUILD_NUMBER-open-login-page-time.csv
cat $JOB_BASE_NAME-$BUILD_NUMBER-login-users.log | grep 'login:' | sed -e 's,\(.*\) INFO.*:\([0-9]\+\)ms.*,\1;\2,g' > $JOB_BASE_NAME-$BUILD_NUMBER-login-time.csv
$COMMON/_csv-to-png.sh $JOB_BASE_NAME-$BUILD_NUMBER-open-login-page-time.csv "Open Login Page Time" "Time" "Open Login Page Time [ms]"
$COMMON/_csv-to-png.sh $JOB_BASE_NAME-$BUILD_NUMBER-login-time.csv "Login Time" "Time" "Login Time [ms]"

echo " Prepare results for Zabbix"
rm -rvf *-zabbix.log
./_zabbix-process-results.sh $JOB_BASE_NAME-$BUILD_NUMBER-report_requests.csv '"GET","auth-api-user"' "auth-api-user"
./_zabbix-process-results.sh $JOB_BASE_NAME-$BUILD_NUMBER-report_requests.csv '"GET","auth-api-user-github-token"' "auth-api-user-github-token"
./_zabbix-process-results.sh $JOB_BASE_NAME-$BUILD_NUMBER-report_requests.csv '"POST","auth-api-token-refresh"' "auth-api-token-refresh"
./_zabbix-process-results.sh $JOB_BASE_NAME-$BUILD_NUMBER-report_requests.csv '"GET","api-user-by-id"' "api-user-by-id"
./_zabbix-process-results.sh $JOB_BASE_NAME-$BUILD_NUMBER-report_requests.csv '"GET","api-user-by-name"' "api-user-by-name"

ZABBIX_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-zabbix.log
if [[ "$ZABBIX_REPORT_ENABLED" = "true" ]]; then
	echo "  Uploading report to zabbix...";
	zabbix_sender -vv -i $ZABBIX_LOG -T -z $ZABBIX_SERVER -p $ZABBIX_PORT;
fi

REPORT_FILE=$JOB_BASE_NAME-$BUILD_NUMBER-report.md
sed -e "s,@@JOB_BASE_NAME@@,$JOB_BASE_NAME,g" report-template.md |
sed -e "s,@@BUILD_NUMBER@@,$BUILD_NUMBER,g" > $REPORT_FILE

# Create HTML report
function filterZabbixValue {
   VALUE=`cat $1 | grep $2 | head -n 1 | cut -d " " -f 4`
   sed -i -e "s,$3,$VALUE,g" $4
}
filterZabbixValue $ZABBIX_LOG "open-login-page-time.min" "@@OPEN_LOGIN_PAGE_TIME_MIN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "open-login-page-time.median" "@@OPEN_LOGIN_PAGE_TIME_MEDIAN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "open-login-page-time.max" "@@OPEN_LOGIN_PAGE_TIME_MAX@@" $REPORT_FILE;

filterZabbixValue $ZABBIX_LOG "login-time.min" "@@LOGIN_TIME_MIN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "login-time.median" "@@LOGIN_TIME_MEDIAN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "login-time.max" "@@LOGIN_TIME_MAX@@" $REPORT_FILE;

filterZabbixValue $ZABBIX_LOG "auth-api-user-rt_min" "@@AUTH_API_USER_MIN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-rt_median" "@@AUTH_API_USER_MEDIAN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-rt_max" "@@AUTH_API_USER_MAX@@" $REPORT_FILE;

filterZabbixValue $ZABBIX_LOG "auth-api-user-github-token-rt_min" "@@AUTH_API_USER_GITHUB_TOKEN_MIN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-github-token-rt_median" "@@AUTH_API_USER_GITHUB_TOKEN_MEDIAN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-github-token-rt_max" "@@AUTH_API_USER_GITHUB_TOKEN_MAX@@" $REPORT_FILE;

filterZabbixValue $ZABBIX_LOG "auth-api-token-refresh-rt_min" "@@AUTH_API_TOKEN_REFRESH_MIN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-token-refresh-rt_median" "@@AUTH_API_TOKEN_REFRESH_MEDIAN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-token-refresh-rt_max" "@@AUTH_API_TOKEN_REFRESH_MAX@@" $REPORT_FILE;

filterZabbixValue $ZABBIX_LOG "api-user-by-id-rt_min" "@@API_USER_BY_ID_MIN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-id-rt_median" "@@API_USER_BY_ID_MEDIAN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-id-rt_max" "@@API_USER_BY_ID_MAX@@" $REPORT_FILE;

filterZabbixValue $ZABBIX_LOG "api-user-by-name-rt_min" "@@API_USER_BY_NAME_MIN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-name-rt_median" "@@API_USER_BY_NAME_MEDIAN@@" $REPORT_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-name-rt_max" "@@API_USER_BY_NAME_MAX@@" $REPORT_FILE;

REPORT_TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S (%Z)'`
sed -i -e "s,@@TIMESTAMP@@,$REPORT_TIMESTAMP,g" $REPORT_FILE

grip --export $REPORT_FILE

echo " Shut Locust slaves down"
$COMMON/__stop-locust-slaves.sh

echo " Check for errors in Locust master log"
if [[ "0" -ne `cat $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log | grep 'Error report' | wc -l` ]]; then echo '[:(] THERE WERE ERRORS OR FAILURES!!!'; else echo '[:)] NO ERRORS OR FAILURES DETECTED.'; fi

#!/bin/bash

source _setenv.sh

export COMMON="common.git"
git clone https://github.com/pmacik/openshiftio-performance-common $COMMON

mkdir -p $LOG_DIR/csv

echo " Wait for the server to become available"
./_wait-for-server.sh
if [ $? -gt 0 ]; then
	exit 1
fi

echo " Login users and get auth tokens"
LOGIN_USERS=openshift-loginusers.git
git clone https://github.com/pmacik/openshiftio-loginusers $LOGIN_USERS

mvn -f $LOGIN_USERS/pom.xml clean compile
cat $USERS_PROPERTIES_FILE > $LOGIN_USERS/target/classes/users.properties
TOKENS_FILE_PREFIX=`readlink -f /tmp/osioperftest.tokens`

echo "  Auth login..."
MVN_LOG=$LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-mvn.log
mvn -f $LOGIN_USERS/pom.xml -l $MVN_LOG exec:java -Dauth.server.address=$SERVER_SCHEME://$SERVER_HOST -Duser.tokens.file=$TOKENS_FILE_PREFIX.auth -Pauth
LOGIN_USERS_LOG=$LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-login-users.log
cat $MVN_LOG | grep login-users-log > $LOGIN_USERS_LOG

echo "  OAuth2 friendly login..."
MVN_LOG=$LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-mvn.log
mvn -f $LOGIN_USERS/pom.xml -l $MVN_LOG exec:java -Dauth.server.address=$SERVER_SCHEME://$SERVER_HOST -Duser.tokens.file=$TOKENS_FILE_PREFIX.oauth2 -Poauth2
LOGIN_USERS_OAUTH2_LOG=$LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-login-users-oauth2.log
cat $MVN_LOG | grep login-users-log > $LOGIN_USERS_OAUTH2_LOG

export TOKENS_FILE=$TOKENS_FILE_PREFIX.oauth2

if [ "$RUN_LOCALLY" != "true" ]; then
	echo "#!/bin/bash
export USER_TOKENS=\"0;0\"
" > $ENV_FILE-master;

	TOKEN_COUNT=`cat $TOKENS_FILE | wc -l`
	i=1
	s=1
	rm -rf $TOKENS_FILE-slave-*;
	if [ $TOKEN_COUNT -ge $SLAVES ]; then
		while [ $i -le $TOKEN_COUNT ]; do
			sed "${i}q;d" $TOKENS_FILE >> $TOKENS_FILE-slave-$s;
			i=$((i+1));
			if [ $s -lt $SLAVES ]; then
				s=$((s+1));
			else
				s=1;
			fi;
		done;
	else
		while [ $s -le $SLAVES ]; do
			sed "${i}q;d" $TOKENS_FILE >> $TOKENS_FILE-slave-$s;
			s=$((s+1));
			if [ $i -lt $TOKEN_COUNT ]; then
				i=$((i+1));
			else
				i=1;
			fi;
		done;
	fi
	for s in $(seq 1 $SLAVES); do
		echo "#!/bin/bash
export USER_TOKENS=\"$(cat $TOKENS_FILE-slave-$s)\"
" > $ENV_FILE-slave-$s;
	done
else
	echo "#!/bin/bash
export USER_TOKENS=\"`cat $TOKENS_FILE`\"
" > $ENV_FILE-master;
fi

echo " Prepare locustfile template"
./_prepare-locustfile.sh auth-api-user.py

if [ "$RUN_LOCALLY" != "true" ]; then
	echo " Shut Locust master down"
	$COMMON/__stop-locust-master.sh

	echo " Shut Locust slaves down"
	SLAVES=10 $COMMON/__stop-locust-slaves.sh

	echo " Start Locust master waiting for slaves"
	$COMMON/__start-locust-master.sh

	echo " Start all the Locust slaves"
	$COMMON/__start-locust-slaves.sh
else
	echo " Shut Locust master down"
	$COMMON/__stop-locust-master-standalone.sh
	echo " Run Locust locally"
	$COMMON/__start-locust-master-standalone.sh
fi
echo " Run test for $DURATION seconds"

sleep $DURATION
if [ "$RUN_LOCALLY" != "true" ]; then
	echo " Shut Locust master down"
	$COMMON/__stop-locust-master.sh TERM

	echo " Download locust reports from Locust master"
	$COMMON/_gather-locust-reports.sh
else
	$COMMON/__stop-locust-master-standalone.sh TERM
fi

echo " Extract CSV data from logs"
$COMMON/_locust-log-to-csv.sh 'GET auth-api-user ' $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'GET auth-api-user-github-token' $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'POST auth-api-token-refresh' $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'POST api-token-refresh ' $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'POST api-token-refresh-grant-type' $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'GET api-user-by-id' $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'GET api-user-by-name' $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log

echo " Generate charts from CSV"
export REPORT_CHART_WIDTH=1000
export REPORT_CHART_HEIGHT=600
for c in $(find *.csv | grep '\-POST_\+\|\-GET_\+'); do echo $c; $COMMON/_csv-response-time-to-png.sh $c; $COMMON/_csv-throughput-to-png.sh $c; $COMMON/_csv-failures-to-png.sh $c; done
function distribution_2_csv {
	HEAD=(`cat $1 | head -n 1 | sed -e 's,",,g' | sed -e 's, ,_,g' | sed -e 's,%,,g' | tr "," " "`)
	DATA=(`cat $1 | grep -F "$2" | sed -e 's,",,g' | sed -e 's, ,_,g' | tr "," " "`)
	NAME=`echo $1 | sed -e 's,-report_distribution,,g' | sed -e 's,\.csv,,g'`-`echo "$2" | sed -e 's,",,g' | sed -e 's, ,_,g;'`

	rm -rf $NAME-rt-histo.csv;
	for i in $(seq 2 $(( ${#HEAD[*]} - 1 )) ); do
		echo "${HEAD[$i]};${DATA[$i]}" >> $NAME-rt-histo.csv;
	done;
}
for c in $(find $LOG_DIR/csv -name '*-report_distribution.csv'); do
	distribution_2_csv $c '"GET api-user-by-id"';
	distribution_2_csv $c '"GET api-user-by-name"';
	distribution_2_csv $c '"POST auth-api-token-refresh"';
	distribution_2_csv $c '"POST api-token-refresh"';
	distribution_2_csv $c '"POST api-token-refresh-grant-type"';
	distribution_2_csv $c '"GET auth-api-user"';
	distribution_2_csv $c '"GET auth-api-user-github-token"';
done
for c in $(find $LOG_DIR/csv -name '*rt-histo.csv'); do echo $c; $COMMON/_csv-rt-histogram-to-png.sh $c; done

cat $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-login-users.log | grep 'open-login-page:' | sed -e 's,\(.*\) INFO.*:\([0-9]\+\)ms.*,\1;\2,g' > $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-open-login-page-time.csv
cat $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-login-users.log | grep 'login:' | sed -e 's,\(.*\) INFO.*:\([0-9]\+\)ms.*,\1;\2,g' > $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-login-time.csv

cat $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-login-users-oauth2.log | grep 'open-login-page:' | sed -e 's,\(.*\) INFO.*:\([0-9]\+\)ms.*,\1;\2,g' > $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-open-login-page-time.csv
cat $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-login-users-oauth2.log | grep 'get-code:' | sed -e 's,\(.*\) INFO.*:\([0-9]\+\)ms.*,\1;\2,g' > $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-get-code-time.csv
cat $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-login-users-oauth2.log | grep 'get-token:' | sed -e 's,\(.*\) INFO.*:\([0-9]\+\)ms.*,\1;\2,g' > $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-get-token-time.csv
cat $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-login-users-oauth2.log | grep 'login:' | sed -e 's,\(.*\) INFO.*:\([0-9]\+\)ms.*,\1;\2,g' > $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-login-time.csv

$COMMON/_csv-to-png.sh $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-open-login-page-time.csv "Open Login Page Time" "Time" "Open Login Page Time [ms]"
$COMMON/_csv-to-png.sh $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-login-time.csv "Login Time" "Time" "Login Time [ms]"

$COMMON/_csv-to-png.sh $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-open-login-page-time.csv "OAuth2: Open Login Page Time" "Time" "Open Login Page Time [ms]"
$COMMON/_csv-to-png.sh $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-get-code-time.csv "OAuth2: Get Code Time" "Time" "Get Code Time [ms]"
$COMMON/_csv-to-png.sh $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-get-token-time.csv "OAuth2: Get Token Time" "Time" "Get Token Time [ms]"
$COMMON/_csv-to-png.sh $LOG_DIR/csv/$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-login-time.csv "OAuth2: Login Time" "Time" "Login Time [ms]"

echo " Prepare results for Zabbix"
rm -rvf $LOG_DIR/*-zabbix.log
export ZABBIX_LOG=$LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-zabbix.log
./_zabbix-process-results.sh $ZABBIX_LOG

if [[ "$ZABBIX_REPORT_ENABLED" = "true" ]]; then
	echo "  Uploading report to zabbix...";
	zabbix_sender -vv -i $ZABBIX_LOG -T -z $ZABBIX_SERVER -p $ZABBIX_PORT;
fi

RESULTS_FILE=$LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-results.md
sed -e "s,@@JOB_BASE_NAME@@,$JOB_BASE_NAME,g" results-template.md |
sed -e "s,@@BUILD_NUMBER@@,$BUILD_NUMBER,g" > $RESULTS_FILE

# Create HTML report
function filterZabbixValue {
   VALUE=`cat $1 | grep " $2" | head -n 1 | cut -d " " -f 4`
   sed -i -e "s,$3,$VALUE,g" $4
}
filterZabbixValue $ZABBIX_LOG "open-login-page-time.min" "@@OPEN_LOGIN_PAGE_TIME_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "open-login-page-time.median" "@@OPEN_LOGIN_PAGE_TIME_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "open-login-page-time.max" "@@OPEN_LOGIN_PAGE_TIME_MAX@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "login-time.min" "@@LOGIN_TIME_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "login-time.median" "@@LOGIN_TIME_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "login-time.max" "@@LOGIN_TIME_MAX@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "oauth2.open-login-page-time.min" "@@OAUTH2_OPEN_LOGIN_PAGE_TIME_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "oauth2.open-login-page-time.median" "@@OAUTH2_OPEN_LOGIN_PAGE_TIME_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "oauth2.open-login-page-time.max" "@@OAUTH2_OPEN_LOGIN_PAGE_TIME_MAX@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "oauth2.get-code-time.min" "@@OAUTH2_GET_CODE_TIME_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "oauth2.get-code-time.median" "@@OAUTH2_GET_CODE_TIME_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "oauth2.get-code-time.max" "@@OAUTH2_GET_CODE_TIME_MAX@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "oauth2.get-token-time.min" "@@OAUTH2_GET_TOKEN_TIME_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "oauth2.get-token-time.median" "@@OAUTH2_GET_TOKEN_TIME_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "oauth2.get-token-time.max" "@@OAUTH2_GET_TOKEN_TIME_MAX@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "oauth2.login-time.min" "@@OAUTH2_LOGIN_TIME_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "oauth2.login-time.median" "@@OAUTH2_LOGIN_TIME_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "oauth2.login-time.max" "@@OAUTH2_LOGIN_TIME_MAX@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "auth-api-user-rt_min" "@@AUTH_API_USER_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-rt_median" "@@AUTH_API_USER_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-rt_max" "@@AUTH_API_USER_MAX@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-rt_average" "@@AUTH_API_USER_AVERAGE@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-failed" "@@AUTH_API_USER_FAILED@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "auth-api-user-github-token-rt_min" "@@AUTH_API_USER_GITHUB_TOKEN_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-github-token-rt_median" "@@AUTH_API_USER_GITHUB_TOKEN_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-github-token-rt_max" "@@AUTH_API_USER_GITHUB_TOKEN_MAX@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-github-token-rt_average" "@@AUTH_API_USER_GITHUB_TOKEN_AVERAGE@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-user-github-token-failed" "@@AUTH_API_USER_GITHUB_TOKEN_FAILED@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "auth-api-token-refresh-rt_min" "@@AUTH_API_TOKEN_REFRESH_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-token-refresh-rt_median" "@@AUTH_API_TOKEN_REFRESH_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-token-refresh-rt_max" "@@AUTH_API_TOKEN_REFRESH_MAX@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-token-refresh-rt_average" "@@AUTH_API_TOKEN_REFRESH_AVERAGE@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "auth-api-token-refresh-failed" "@@AUTH_API_TOKEN_REFRESH_FAILED@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "api-token-refresh-rt_min" "@@API_TOKEN_REFRESH_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-token-refresh-rt_median" "@@API_TOKEN_REFRESH_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-token-refresh-rt_max" "@@API_TOKEN_REFRESH_MAX@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-token-refresh-rt_average" "@@API_TOKEN_REFRESH_AVERAGE@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-token-refresh-failed" "@@API_TOKEN_REFRESH_FAILED@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "api-token-refresh-grant-type-rt_min" "@@API_TOKEN_REFRESH_GRANT_TYPE_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-token-refresh-grant-type-rt_median" "@@API_TOKEN_REFRESH_GRANT_TYPE_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-token-refresh-grant-type-rt_max" "@@API_TOKEN_REFRESH_GRANT_TYPE_MAX@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-token-refresh-grant-type-rt_average" "@@API_TOKEN_REFRESH_GRANT_TYPE_AVERAGE@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-token-refresh-grant-type-failed" "@@API_TOKEN_REFRESH_GRANT_TYPE_FAILED@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "api-user-by-id-rt_min" "@@API_USER_BY_ID_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-id-rt_median" "@@API_USER_BY_ID_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-id-rt_max" "@@API_USER_BY_ID_MAX@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-id-rt_average" "@@API_USER_BY_ID_AVERAGE@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-id-failed" "@@API_USER_BY_ID_FAILED@@" $RESULTS_FILE;

filterZabbixValue $ZABBIX_LOG "api-user-by-name-rt_min" "@@API_USER_BY_NAME_MIN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-name-rt_median" "@@API_USER_BY_NAME_MEDIAN@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-name-rt_max" "@@API_USER_BY_NAME_MAX@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-name-rt_average" "@@API_USER_BY_NAME_AVERAGE@@" $RESULTS_FILE;
filterZabbixValue $ZABBIX_LOG "api-user-by-name-failed" "@@API_USER_BY_NAME_FAILED@@" $RESULTS_FILE;

REPORT_TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S (%Z)'`
sed -i -e "s,@@TIMESTAMP@@,$REPORT_TIMESTAMP,g" $RESULTS_FILE

REPORT_FILE=$LOG_DIR/$JOB_BASE_NAME-report.md
cat README.md $RESULTS_FILE > $REPORT_FILE
if [ -z "$GRIP_USER" ]; then
	grip --export $REPORT_FILE
else
	grip --user=$GRIP_USER --pass=$GRIP_PASS --export $REPORT_FILE
fi

if [ "$RUN_LOCALLY" != "true" ]; then
	echo " Shut Locust slaves down"
	$COMMON/__stop-locust-slaves.sh
fi

echo " Check for errors in Locust master log"
if [[ "0" -ne `cat $LOG_DIR/$JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log | grep 'Error report' | wc -l` ]]; then echo '[:(] THERE WERE ERRORS OR FAILURES!!!'; else echo '[:)] NO ERRORS OR FAILURES DETECTED.'; fi

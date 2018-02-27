#!/bin/bash

source ./_setenv.sh


export COMMON="common.git"
#rm -vf *.log
#rm -vf *.csv
#rm -vf *.png

 git clone https://github.com/pmacik/openshiftio-performance-common $COMMON

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

#echo "  Auth login..."
#echo "SKIPPING"
#MVN_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-mvn.log
#mvn -f $LOGIN_USERS/pom.xml -l $MVN_LOG exec:java -Dauth.server.address=$SERVER_SCHEME://$SERVER_HOST -Duser.tokens.file=$TOKENS_FILE_PREFIX.auth -Pauth
#LOGIN_USERS_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-login-users.log
#cat $MVN_LOG | grep login-users-log > $LOGIN_USERS_LOG

echo "  OAuth2 friendly login..."
MVN_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-oauth2-mvn.log
mvn -f $LOGIN_USERS/pom.xml -l $MVN_LOG exec:java -Dauth.server.address=$SERVER_SCHEME://$SERVER_HOST -Duser.tokens.file=$TOKENS_FILE_PREFIX.oauth2 -Poauth2
LOGIN_USERS_OAUTH2_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-login-users-oauth2.log
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

#echo " Prepare locustfile template"
#./_prepare-locustfile.sh auth-api-user.py

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
echo " Extract CSV data from logs:"
$COMMON/_locust-log-to-csv.sh 'POST createWorkspace' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'GET getWorkspaceStatus' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'REPEATED_GET timeForStartingWorkspace' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'POST startWorkspace' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'DELETE stopWorkspace' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log
$COMMON/_locust-log-to-csv.sh 'DELETE deleteWorkspace' $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log

echo " Generate charts from CSV"
export REPORT_CHART_WIDTH=1000
export REPORT_CHART_HEIGHT=600
for c in $(find *.csv | grep '\-POST_\+\|\-GET_\+\|\-REPEATED_GET_\+\|\-DELETE_\+'); do echo $c; $COMMON/_csv-response-time-to-png.sh $c; $COMMON/_csv-throughput-to-png.sh $c; $COMMON/_csv-failures-to-png.sh $c; done
function distribution_2_csv {
 	HEAD=(`cat $1 | head -n 1 | sed -e 's,",,g' | sed -e 's, ,_,g' | sed -e 's,%,,g' | tr "," " "`)
	DATA=(`cat $1 | grep -F "$2" | sed -e 's,",,g' | sed -e 's, ,_,g' | tr "," " "`)
	NAME=`echo $1 | sed -e 's,-report_distribution,,g' | sed -e 's,\.csv,,g'`-`echo "$2" | sed -e 's,",,g' | sed -e 's, ,_,g;'`

	rm -rf $NAME-rt-histo.csv;
	for i in $(seq 2 $(( ${#HEAD[*]} - 1 )) ); do
		echo "${HEAD[$i]};${DATA[$i]}" >> $NAME-rt-histo.csv;
	done;
}

 for c in $(find *.csv | grep '\-report_distribution.csv'); do
 	distribution_2_csv $c '"POST createWorkspace"';
 	distribution_2_csv $c '"GET getWorkspaceStatus"';
 	distribution_2_csv $c '"REPEATED_GET timeForStartingWorkspace"';
 	distribution_2_csv $c '"POST startWorkspace"';
 	distribution_2_csv $c '"DELETE stopWorkspace"';
 	distribution_2_csv $c '"DELETE deleteWorkspace"';
 done
 export REPORT_CHART_WIDTH=1000
 export REPORT_CHART_HEIGHT=600
 for c in $(find *rt-histo.csv); do echo $c; $COMMON/_csv-rt-histogram-to-png.sh $c; done
#
 echo " Prepare results for Zabbix"
 rm -rvf *-zabbix.log
 export ZABBIX_LOG=$JOB_BASE_NAME-$BUILD_NUMBER-zabbix.log
 ./_zabbix-process-results.sh $ZABBIX_LOG

 if [[ "$ZABBIX_REPORT_ENABLED" = "true" ]]; then
 	echo "  Uploading report to zabbix...";
 	zabbix_sender -vv -i $ZABBIX_LOG -T -z $ZABBIX_SERVER -p $ZABBIX_PORT;
 fi

 RESULTS_FILE=$JOB_BASE_NAME-$BUILD_NUMBER-results.md
 sed -e "s,@@JOB_BASE_NAME@@,$JOB_BASE_NAME,g" results-template.md |
 sed -e "s,@@BUILD_NUMBER@@,$BUILD_NUMBER,g" > $RESULTS_FILE

 # Create HTML report
 function filterZabbixValue {
    VALUE=`cat $1 | grep $2 | head -n 1 | cut -d " " -f 4`
    sed -i -e "s,$3,$VALUE,g" $4
 }
 filterZabbixValue $ZABBIX_LOG "createWorkspace-min" "@@CREATE_WORKSPACE_MIN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "createWorkspace-median" "@@CREATE_WORKSPACE_MEDIAN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "createWorkspace-max" "@@CREATE_WORKSPACE_MAX@@" $RESULTS_FILE;

 filterZabbixValue $ZABBIX_LOG "startWorkspace-min" "@@START_WORKSPACE_MIN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "startWorkspace-median" "@@START_WORKSPACE_MEDIAN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "startWorkspace-max" "@@START_WORKSPACE_MAX@@" $RESULTS_FILE;

 filterZabbixValue $ZABBIX_LOG "getWorkspaceStatus-min" "@@GET_WORKSPACE_STATUS_MIN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "getWorkspaceStatus-median" "@@GET_WORKSPACE_STATUS_MEDIAN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "getWorkspaceStatus-max" "@@GET_WORKSPACE_STATUS_MAX@@" $RESULTS_FILE;

 filterZabbixValue $ZABBIX_LOG "timeForStartingWorkspace-min" "@@TIME_FOR_STARTING_WORKSPACE_MIN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "timeForStartingWorkspace-median" "@@TIME_FOR_STARTING_WORKSPACE_MEDIAN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "timeForStartingWorkspace-max" "@@TIME_FOR_STARTING_WORKSPACE_MAX@@" $RESULTS_FILE;

 filterZabbixValue $ZABBIX_LOG "stopWorkspace-min" "@@STOP_WORKSPACE_MIN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "stopWorkspace-median" "@@STOP_WORKSPACE_MEDIAN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "stopWorkspace-max" "@@STOP_WORKSPACE_MAX@@" $RESULTS_FILE;

 filterZabbixValue $ZABBIX_LOG "deleteWorkspace-min" "@@DELETE_WORKSPACE_MIN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "deleteWorkspace-median" "@@DELETE_WORKSPACE_MEDIAN@@" $RESULTS_FILE;
 filterZabbixValue $ZABBIX_LOG "deleteWorkspace-max" "@@DELETE_WORKSPACE_MAX@@" $RESULTS_FILE;

 REPORT_TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S (%Z)'`
 sed -i -e "s,@@TIMESTAMP@@,$REPORT_TIMESTAMP,g" $RESULTS_FILE

 REPORT_FILE=$JOB_BASE_NAME-report.md
 cat README.md $RESULTS_FILE > $REPORT_FILE
# if [ -z "$GRIP_USER" ]; then
# 	grip --export $REPORT_FILE
# else
# 	grip --user=$GRIP_USER --pass=$GRIP_PASS --export $REPORT_FILE
# fi

 if [ "$RUN_LOCALLY" != "true" ]; then
 	echo " Shut Locust slaves down"
 	$COMMON/__stop-locust-slaves.sh
 fi

 echo " Check for errors in Locust master log"
 if [[ "0" -ne `cat $JOB_BASE_NAME-$BUILD_NUMBER-locust-master.log | grep 'Error report' | wc -l` ]]; then echo '[:(] THERE WERE ERRORS OR FAILURES!!!'; else echo '[:)] NO ERRORS OR FAILURES DETECTED.'; fi

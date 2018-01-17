#!/bin/bash

#source _setenv.sh

KILLSIGNAL=${1:-9}

echo "Killing a Locust master ..."
bash -c 'kill -'$KILLSIGNAL' `ps aux | grep locust | grep -v grep | grep python | sed -e "s,[^0-9]* \([0-9]\+\) .*,\1,g"`' | echo "Done";


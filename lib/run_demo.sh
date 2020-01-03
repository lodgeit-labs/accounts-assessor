#!/usr/bin/env bash
set -x
killall swipl; 
#git pull; 
swipl ../lib/run_daemon_debug.pl --http=7778  --debug="http(request)" --debug="process_data"   --output=log; 
netstat -ltnp


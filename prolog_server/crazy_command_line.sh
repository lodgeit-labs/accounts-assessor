killall swipl; git stash; git fetch; git checkout granular3; git pull; swipl run_daemon.pl --http=7778  --debug="http(request)"   --output=log; netstat -ltnp

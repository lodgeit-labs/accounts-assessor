#!/usr/bin/env bash
set -x
/app/sources/wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 300
cd /app/sources/common/libs/remoulade/remoulade/api/
echo "begin"





_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM
flask run -h "0.0.0.0" --no-debugger &
#--no-reload
child=$! 
wait "$child"
echo "end"


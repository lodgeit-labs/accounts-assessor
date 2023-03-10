#!/usr/bin/env bash
set -x
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 0
../wait-for-it/wait-for-it.sh $(echo "$REMOULADE_API" | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\)\(:\([0-9]\{1,5\}\)\)\?.*/\2\3/") -t 0


_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM
PYTHONPATH=/app/sources/common/libs/remoulade/ watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  --  remoulade --threads 1 main invoke_rpc &
child=$!
wait "$child"
echo "end"






#!/usr/bin/env bash
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 0
../wait-for-it/wait-for-it.sh remoulade-api:5005 -t 0

_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM

set -xv
watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- ./start2.sh  &
child=$!
wait "$child"
echo "end"






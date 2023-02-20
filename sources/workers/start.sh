#!/usr/bin/env bash
set -x
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 300


_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM
PYTHONPATH=/app/sources/common/libs/remoulade/ watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  --  remoulade --threads 1 main&
child=$!
wait "$child"
echo "end"






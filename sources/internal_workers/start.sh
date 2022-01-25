#!/usr/bin/env bash
set -x
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 300


_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM
#PYTHONPATH=/usr/lib/python3.9/site-packages/ watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- remoulade selftest &
PYTHONPATH=/app/sources/common/libs/remoulade/ watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- remoulade selftest &
child=$!
wait "$child"
echo "end"






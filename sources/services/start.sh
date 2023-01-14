#!/usr/bin/env bash
set -xv
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 300

_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM
PYTHONPATH=/app/sources/common/libs/remoulade/ watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- python3 -O `which uvicorn` app.main:app --proxy-headers --host 0.0.0.0 --port 17788 &
child=$!
wait "$child"
echo "end"






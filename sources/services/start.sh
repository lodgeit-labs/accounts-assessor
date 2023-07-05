#!/usr/bin/env bash
set -xv
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 0
cd app
_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM
watchmedo auto-restart --debounce-interval 1 --interval 5 -d .  -d ../../common  --patterns="*.py;*.egg" --recursive  -- python3 -O `which uvicorn` main:app --proxy-headers --host 0.0.0.0 --port 17788 &
child=$!
wait "$child"
echo "end"






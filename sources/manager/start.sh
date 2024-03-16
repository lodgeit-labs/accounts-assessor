#!/usr/bin/env bash

set -x
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 0
../wait-for-it/wait-for-it.sh $(echo "$REMOULADE_API" | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\)\(:\([0-9]\{1,5\}\)\)\?.*/\2\3/") -t 0


_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child0"
  kill -TERM "$child1"
}
trap _term SIGTERM


pwd

if [ ! -z $WATCHMEDO ]; then
  #QUEUE=health watchmedo auto-restart --debounce-interval 1 --interval $WATCHMEDO_INTERVAL -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- ./start2.sh 9112 &
  cat &
  child0=$!
  QUEUE=default watchmedo auto-restart --debounce-interval 1 --interval $WATCHMEDO_INTERVAL -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- ./start2.sh 9111 &
  child1=$!
else
  #QUEUE=health ./start2.sh 9112 &
  cat &
  child0=$!
  QUEUE=default ./start2.sh 9111 &
  child1=$!
fi


wait "$child1"
kill -TERM "$child0"
wait "$child0"

echo ".process end ======================================================================= end process ."

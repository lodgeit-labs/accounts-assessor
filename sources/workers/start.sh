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



export PYTHONPATH=/app/sources/common/libs/remoulade/


if [ ! -z $WATCHMEDO ]; then
  watchmedo auto-restart --debounce-interval 1 --interval $WATCHMEDO_INTERVAL -d .  -d ../common  --patterns="*.py;*.egg" --recursive  --  remoulade --prefetch-multiplier 1 --queues health  --threads 1 worker &
  child0=$!
  watchmedo auto-restart --debounce-interval 1 --interval $WATCHMEDO_INTERVAL -d .  -d ../common  --patterns="*.py;*.egg" --recursive  --  remoulade --prefetch-multiplier 1 --queues default --threads 1 worker &
  child1=$!
else
  remoulade --prefetch-multiplier 1 --queues health  --threads 1 worker &
  child0=$!
  remoulade --prefetch-multiplier 1 --queues default --threads 1 worker &
  child1=$!
fi


wait "$child1"
kill -TERM "$child0"
wait "$child0"

echo ".process end ======================================================================= end process ."






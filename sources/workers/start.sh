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



export PYTHONPATH /app/sources/common/libs/remoulade/

set MODULES main invoke_rpc

watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  --  remoulade --prefetch-multiplier 1 --queues health  --threads 1 $MODULES &
child0=$!

watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  --  remoulade --prefetch-multiplier 1 --queues default --threads 1 $MODULES &
child1=$!


wait "$child0"
kill -TERM "$child1"
wait "$child1"

echo "end"






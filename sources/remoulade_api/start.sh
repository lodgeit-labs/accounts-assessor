#!/usr/bin/env bash
set -x
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 0

_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM
flask run -h "0.0.0.0" --port 5005 --no-debugger & #--no-reload # the reloader is too greedy...
child=$! 
wait "$child"
echo ".process end ======================================================================= end process ."


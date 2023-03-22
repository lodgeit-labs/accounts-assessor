#!/usr/bin/env bash

./manage.py migrate
CMD="runserver ${DJANGO_ARGS} $@"
echo $CMD ...

_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM
./manage.py $CMD &
child=$!
wait "$child"
echo "end"





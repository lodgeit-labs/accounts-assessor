#!/usr/bin/env bash

./manage.py migrate
CMD="runserver ${DJANGO_ARGS} $@"
echo $CMD ...
./manage.py $CMD

#!/bin/sh
./manage.py migrate
./manage.py check --deploy
./manage.py runserver ${DJANGO_ARGS} $@
echo "django ended."

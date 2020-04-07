#!/bin/sh
export DJANGO_SETTINGS_MODULE="frontend_server.settings_prod"
. ./run_common0.sh
./manage.py check --deploy
./manage.py runserver $@
echo "django ended."

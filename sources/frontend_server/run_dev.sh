#!/bin/sh
export DJANGO_SETTINGS_MODULE="frontend_server.settings_dev"
export DEBUG=true
. ./run_common0.sh
./manage.py runserver $@
echo "django ended."

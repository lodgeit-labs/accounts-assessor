#!/bin/sh
export DJANGO_SETTINGS_MODULE="frontend_server.settings_prod"
export DJANGO_SETTINGS_MODULE="frontend_server.settings_dev"
./manage.py migrate
./manage.py check --deploy
./manage.py runserver $@
echo "django ended."

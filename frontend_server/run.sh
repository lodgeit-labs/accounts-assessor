#!/bin/bash
if [ "$DEBUG" == "true" ]
then
	export DJANGO_SETTINGS_MODULE="frontend_server.settings_dev"
else
	export DJANGO_SETTINGS_MODULE="frontend_server.settings_prod"
fi
. ./run_common0.sh
if [ ! "$DEBUG" == "true" ]
then
	./manage.py check --deploy
fi
./manage.py runserver $@
echo "django ended."

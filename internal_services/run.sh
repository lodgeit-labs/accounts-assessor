#! /bin/sh
./init.sh
. venv/bin/activate
./manage.py migrate
./manage.py runserver $@
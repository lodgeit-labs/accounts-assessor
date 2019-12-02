#! /bin/sh
. venv/bin/activate
./manage.py migrate
./manage.py runserver $1

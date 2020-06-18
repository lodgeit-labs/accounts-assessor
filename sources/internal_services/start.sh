#!/usr/bin/env bash

./manage.py migrate
./manage.py runserver $@

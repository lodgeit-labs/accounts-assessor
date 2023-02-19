#!/usr/bin/env bash

virtualenv -p /usr/bin/python3 venv
. ./venv/bin/activate
python3 -m pip install --no-cache-dir -r requirements.txt
python3 -m pip install --no-cache-dir -e ../common/libs/remoulade/[rabbitmq,redis,postgres]

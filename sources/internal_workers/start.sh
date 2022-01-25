#!/usr/bin/env bash
set -xv
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 300
PYTHONPATH=/usr/lib/python3.9/site-packages/ watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- remoulade selftest




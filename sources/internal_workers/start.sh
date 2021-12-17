#!/usr/bin/env bash
set -xv
../wait-for-it/wait-for-it.sh rabbitmq:5672 -t 300
watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- python3 -O `which celery`  -A celery_module worker -c 3 -E   $@

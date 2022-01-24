#!/usr/bin/env bash
set -xv
../wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 300

watchmedo auto-restart -d .  -d ../common  --patterns="*.py;*.egg" --recursive  -- python3.9 -O `which uvicorn` app.main:app --proxy-headers --host 0.0.0.0 --port 7788





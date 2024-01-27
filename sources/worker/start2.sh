#!/usr/bin/env bash

python3 -O `which uvicorn` app.main:app --proxy-headers --host 127.0.0.1 --port 1111  --workers $WORKER_PROCESSES --log-level debug

#!/usr/bin/env bash

PYTHONPATH=../common/libs/remoulade/

python3 -O `which uvicorn` app.main:app --proxy-headers --host 0.0.0.0 --port 7788  --workers 8 --log-level info #debug

#python3 -O `which gunicorn` app/main.py  --proxy-headers --bind 0.0.0.0:7788 --workers 4 --worker-class uvicorn.workers.UvicornWorker --log-level trace $@

#!/usr/bin/env bash

PYTHONPATH=../common/libs/remoulade/


#python3 -O `which uvicorn` app.main:app --proxy-headers --host 0.0.0.0 --port 7788  --workers 4 # --log-level trace $@

python3 -O `which gunicorn` app.main:app --workers 10 --worker-class uvicorn.workers.UvicornH11Worker --bind 0.0.0.0:7788

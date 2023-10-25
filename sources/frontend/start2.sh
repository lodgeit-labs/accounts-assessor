#!/usr/bin/env bash
PYTHONPATH=../common/libs/remoulade/ python3 -O `which uvicorn` app.main:app --proxy-headers --host 0.0.0.0 --port 7788  --workers 4 # --log-level trace $@

#gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:80
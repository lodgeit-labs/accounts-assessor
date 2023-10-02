#!/usr/bin/env bash
set -xv

python3 -O `which uvicorn` app.main:app --proxy-headers --host 0.0.0.0 --port 17788  --log-config=log_conf.yaml

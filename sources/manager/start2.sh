#!/usr/bin/env bash
set -xv

export PYTHONPATH=../common/libs/remoulade/

# https://github.com/benoitc/gunicorn/issues/1138
python3 -O `which uvicorn` app.main:app  --host '' --workers 1 --log-level info --port $@

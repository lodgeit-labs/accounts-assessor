#!/usr/bin/env bash
set -xv

export PYTHONPATH=../common/libs/remoulade/
python3 -O `which uvicorn` app.main:app --host 0.0.0.0 --workers 1?? --log-level trace  --port $@






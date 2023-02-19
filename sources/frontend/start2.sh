#!/usr/bin/env bash
PYTHONPATH=/app/sources/common/libs/remoulade/ python3 -O `which uvicorn` app.main:app --proxy-headers --host 0.0.0.0 --port 7788 --log-level trace

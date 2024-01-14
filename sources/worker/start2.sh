#!/usr/bin/env fish

python3 -O (which uvicorn) app.main:app --proxy-headers --host 127.0.0.1 --port 1111  --workers 1 --log-level trace

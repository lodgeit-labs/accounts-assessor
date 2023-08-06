#!/usr/bin/env bash
curl  --trace-time --trace-ascii --retry-connrefused  --retry-delay 1 --retry 100 -L -S --fail --max-time 320 --header 'Content-Type: application/json' --data '---' http://localhost:8877/health_check

#!/usr/bin/env bash
set -xv
python3 -O `which celery` -A celery_module worker -c 1 -E   $@


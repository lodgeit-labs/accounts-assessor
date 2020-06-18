#!/usr/bin/env bash
python3 -O `which celery` -c 1  -E -A celery_module worker $@

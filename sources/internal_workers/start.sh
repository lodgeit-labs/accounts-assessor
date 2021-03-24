#!/usr/bin/env bash
set -xv
python3 -O `which celery` worker -c 1 -E -A celery_module  $@


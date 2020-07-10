#!/usr/bin/env bash
DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )")"
cd $DIR
. $DIR/../../venv/bin/activate
python3 -O `which celery` -c 1  -E -A celery_module worker $@

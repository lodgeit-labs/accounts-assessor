#!/usr/bin/env bash
DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )")"
cd $DIR
. ./venv/bin/activate
SECRETS_DIR=../../secrets/nodocker SECRET__CELERY_RESULT_BACKEND_URL='redis://localhost' PYTHONUNBUFFERED=true CELERY_QUEUE_NAME=q7788 SECRET__INTERNAL_SERVICES_SERVER_URL=\"http://localhost:17788\" \
python3 -O `which celery`  -A celery_module   worker --hostname w7788  --loglevel=info  $@

#!/usr/bin/env bash

DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )")";cd $DIR

. ./venv/bin/activate
SECRETS_DIR=../../secrets/nodocker RABBITMQ_URL=localhost:5672 ./start.sh

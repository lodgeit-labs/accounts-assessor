#!/usr/bin/env bash

export RABBITMQ_URL=localhost:5672

DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )")";cd $DIR

. ./venv/bin/activate
SECRETS_DIR=../../secrets/nodocker ./start.sh

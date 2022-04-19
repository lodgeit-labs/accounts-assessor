#!/usr/bin/env bash

DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )")";cd $DIR

. ./venv/bin/activate
SECRETS_DIR=../../secrets/nodocker ./start.sh

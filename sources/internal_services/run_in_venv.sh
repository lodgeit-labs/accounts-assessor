#!/usr/bin/env bash
DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )")"
cd $DIR
. $DIR/../../venv/bin/activate
./start.sh $@

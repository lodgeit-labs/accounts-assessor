#!/usr/bin/env bash
python3 -m venv venv
DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )")"
. $DIR/venv/bin/activate
python3 -m pip install wheel
python3 -m pip install -r requirements.txt

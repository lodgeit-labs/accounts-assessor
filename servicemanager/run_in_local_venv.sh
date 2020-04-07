#!/usr/bin/env bash
DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )")"
. $DIR/venv/bin/activate
$DIR/servicemanager.py $@

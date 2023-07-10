#!/usr/bin/env bash

set -x
set -e

cd "$(dirname "$(readlink -f -- "$0")")"

./first_run.sh
./up.sh

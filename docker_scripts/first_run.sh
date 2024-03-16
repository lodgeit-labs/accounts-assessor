#!/usr/bin/env bash

set -x
set -e

cd "$(dirname "$(readlink -f -- "$0")")"

FLAG=$(./flag.sh)

[ -f $FLAG ] && { echo -e "not initing again, $FLAG found.\n"; exit 0; }

rm -rf venv
./first_run0.sh
./first_run1.sh
./first_run2.sh
touch $FLAG
./first_run999.sh
./init_configs.sh


#!/usr/bin/env bash

cd "$(dirname "$(readlink -f -- "$0")")"

set FLAG ~/robust_first_run_v2_done.flag
cat $FLAG && { echo "not initing again"; exit 0; }

./first_run0.sh
./first_run1.sh
./first_run1b.sh
./first_run2.sh

touch $FLAG


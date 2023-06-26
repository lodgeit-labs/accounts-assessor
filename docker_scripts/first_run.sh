#!/usr/bin/env bash

set -x
set -e

cd "$(dirname "$(readlink -f -- "$0")")"

FLAG=~/robust_first_run_v6_done.flag

cat $FLAG && { echo "not initing again"; exit 0; }

./first_run0.sh
./first_run1.sh
./first_run1b.sh
./first_run2.sh

touch $FLAG


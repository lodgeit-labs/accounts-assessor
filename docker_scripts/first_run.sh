#!/usr/bin/env bash

cd "$(dirname "$(readlink -f -- "$0")")"

cat ~/robust_first_run_v1_done.flag && exit 0

./first_run0.sh
./first_run1.sh
./first_run1b.sh
./first_run2.sh

touch ~/robust_first_run_v1_done.flag


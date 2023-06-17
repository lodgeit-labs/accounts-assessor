#!/usr/bin/env bash

cd "${0%/*}" # https://stackoverflow.com/questions/3349105/how-can-i-set-the-current-working-directory-to-the-directory-of-the-script-in-ba

cat ~/robust_first_run_v1_done.flag && exit 0

./first_run0.sh
./first_run1.sh
./first_run1b.sh
./first_run2.sh

touch ~/robust_first_run_v1_done.flag


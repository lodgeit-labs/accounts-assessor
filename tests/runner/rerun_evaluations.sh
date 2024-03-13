#!/usr/bin/env fish

rm ~/robust_tests/latest/summary.json ~/robust_tests/latest/**/evaluation.json;   rm /tmp/robust_testsuite_runlog; reset;echo -e "\e[3J"; PYTHONPATH=(pwd) luigi --module runner.tests2 --Permutations-robust-server-url http://jj.internal:8877  Summary --Permutations-suite ../endpoint_tests/ledger/  --workers=20 --Summary-session (readlink -f ~/robust_tests/latest/)

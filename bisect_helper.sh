#!/usr/bin/env bash
cd prolog_server; 
swipl -s ../tests/run_tests.pl  -g halt |  grep -v 'tests failed'
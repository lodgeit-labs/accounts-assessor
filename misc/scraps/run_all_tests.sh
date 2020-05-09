#!/usr/bin/env bash

reset;echo -e "\e[3J";   swipl -s ../lib/dev_runner.pl   --problem_lines_whitelist=problem_lines_whitelist  ../tests/endpoint_tests/endpoint_tests2.pl  "set_flag(overwrite_response_files, false), set_flag(add_missing_response_files, false), run_tests"

#!/usr/bin/env python3

import sys, subprocess, shlex

argv = sys.argv

FILEPATH = argv[-1]
if FILEPATH.startswith('tests/'):
	FILEPATH = FILEPATH[len('tests/'):]

endpoint_type = FILEPATH.split('/')[0]

args = argv[1:-1]
debug = ''
debug = 'debug(endpoint_tests),'

cmd = shlex.split(f"""--problem_lines_whitelist=problem_lines_whitelist  ../lib/endpoint_tests.pl  "set_flag(overwrite_response_files, false), set_flag(add_missing_response_files, false), set_prolog_flag(grouped_assertions,true), {debug} set_prolog_flag(testcase, ({endpoint_type}, '{FILEPATH}')), run_tests(endpoints:testcase)" """)

subprocess.run(['swipl', '-s', '../lib/dev_runner.pl', '--'] + cmd)









#!/usr/bin/env python3

import sys, subprocess, shlex
argv = sys.argv

FILEPATH = argv[-1]
args = argv[1:-1]
 
subprocess.run(shlex.split("swipl -s ../lib/dev_runner.pl --problem_lines_whitelist problem_lines_whitelist  -- ../lib/debug1.pl") + args + ["prolog_server:process_data_cmdline('" + FILEPATH + "')"])

#!/usr/bin/env python3

import sys, subprocess, shlex
argv = sys.argv

FILEPATH = argv[-1]
args = argv[1:-1]
cmd = shlex.split("swipl -s ../lib/dev_runner.pl --problem_lines_whitelist problem_lines_whitelist -s ../lib/debug1.pl") + args + ["-g process_request:process_request_cmdline('" + FILEPATH + "')"]
print(' '.join(cmd))
subprocess.run(cmd)

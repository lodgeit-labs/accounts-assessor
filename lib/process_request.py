#!/usr/bin/env python3

#from frontend_server.lib import invoke_rpc_cmdline

import sys, subprocess, shlex
argv = sys.argv

FILEPATH = argv[-1]
args = argv[1:-1]
cmd = shlex.split("swipl -s ../lib/dev_runner.pl --problem_lines_whitelist ../misc/problem_lines_whitelist -s ../lib/debug1.pl") + args + ["-g lib:process_request_cmdline('" + FILEPATH + "')"]
print(' '.join(cmd))
subprocess.run(cmd)

#!/usr/bin/env python3


import sys, subprocess
argv = sys.argv


FILEPATH = argv[-1]
args = argv[1:-1]

#print(FILEPATH)
#print(viewer)
#print(args)

#subprocess.run(['reset'])
subprocess.run(['swipl', '-s', '../lib/dev_runner.pl', '--'] + args + ["prolog_server:process_data_cmdline('" + FILEPATH + "')"])

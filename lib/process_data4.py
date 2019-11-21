#!/usr/bin/env python3


import sys, subprocess
argv = sys.argv


FILEPATH = argv[-1]
viewer = argv[-2]
args = argv[1:-2]

#print(FILEPATH)
#print(viewer)
#print(args)

#subprocess.run(['reset'])
subprocess.run(['swipl', '-s', '../lib/dev_runner.pl', '--'] + args + ['-v', viewer,  "prolog_server:process_data_cmdline('" + FILEPATH + "')"])

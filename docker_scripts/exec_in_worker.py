#!/usr/bin/env python3




import shlex, subprocess, logging, os
try:
	import click
except:
	print('please install:\npython3 -m pip install --user -U click')
	exit(1)





sq = shlex.quote
ss = shlex.split

def co(cmd):
	return subprocess.check_output(cmd, text=True, universal_newlines=True)
def cc(cmd):
	return subprocess.check_call(cmd, text=True, universal_newlines=True)





l = logging.getLogger()
l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())





RUNNING_CONTAINER_ID = co(['./lib/get_id_of_running_worker_container.py'])[:-1]




print('worker: ' + RUNNING_CONTAINER_ID)


#!/usr/bin/env python3

import sys, os, shlex

import fire

import invoke_rpc
from tasking import remoulade
from misc import convert_request_files

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))




"""
We have two main ways of invoking prolog:
	1. "RPC" - we send a json request to a server, and get a json response back - or at least it could be a server. 
	In practice, the overhead of launching swipl (twice when debugging) is minimal, so we just launch it for each request.
	( - a proper tcp (http?) server plumbing for our RPC was never written or needed yet).
	
	There are also two ways to pass the goal to swipl, either it's passed on the command line, or it's sent to stdin.
	The stdin method causes problems when the toplevel breaks on an exception, so it's not used, but a bit of the code
	might get reused now, because we will again be generating a goal string that can be copy&pasted into swipl.

"""



def call_remote_rpc_job(msg, queue='default'):
	return local_rpc.send_with_options(kwargs={'msg':msg}, queue_name=queue).result.get(block=True, timeout=1000 * 1000)

@remoulade.actor(alternative_queues=["health"])
def local_rpc(msg, options):
	return invoke_rpc.call_prolog(msg, options)

def trigger_remote_calculator_job(**kwargs):
	return local_calculator.send(kwargs=kwargs)

@remoulade.actor(timeout=999999999999)
def local_calculator(
	request_directory: str,
	request_files: list[str] | None = None,
	request_format='rdf',
	server_url='http://localhost:8877',
	options=None
):

	if request_files is None:
		request_files = find_request_files_in_directory(request_directory)
	request_files = convert_request_files(request_files)

	msg = dict(
		method='calculator',
		params=dict(
			request_files = request_files,
			request_directory = request_directory,
			request_format = request_format,
			server_url = server_url
		)
	)

	return invoke_rpc.call_prolog_calculator(msg, options)


def local_calculator(
	request_directory: str,
	request_files: list[str],
	request_format='rdf',
	server_url='http://localhost:8877'):







def run_last_request_outside_of_docker(self):
	"""
	you should run this script from server_root/

	you should also have `services` running on the host (it doesnt matter that it's simultaneously running in docker), because they have to access files by the paths that `workers` sends them.
	"""
	tmp_volume_data_path = '/var/lib/docker/volumes/robust_tmp/_data/'
	os.system('sudo chmod -R o+rX '+tmp_volume_data_path)
	last_request_host_path = tmp_volume_data_path + os.path.split(os.readlink(tmp_volume_data_path+'last_request'))[-1]

	self.local_calculator(self.prepare_calculation(last_request_host_path))



if __name__ == "__main__":
	fire.Fire()

#!/usr/bin/env python3


import os
import shlex

import invoke_rpc
from fs_utils import files_in_dir
from tasking import remoulade
from misc import convert_request_files
from tmp_dir_path import get_tmp_directory_absolute_path, update_last_request_symlink

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
	return local_rpc.send_with_options(kwargs={'msg':msg}, queue_name=queue)

@remoulade.actor(alternative_queues=["health"])
def local_rpc(msg, options=None):
	return invoke_rpc.call_prolog(msg, options)

def trigger_remote_calculator_job(**kwargs):
	return local_calculator.send_with_options(kwargs=kwargs)

@remoulade.actor(time_limit=1000*60*60*24*365*1000)
def local_calculator(
	request_directory: str,
	public_url='http://localhost:8877',
	options=None
):
	msg = dict(
		method='calculator',
		params=dict(
			request_tmp_directory_name = request_directory,
			request_files = convert_request_files(files_in_dir(get_tmp_directory_absolute_path(request_directory))),
			public_url = public_url
		)
	)
	update_last_request_symlink(request_directory)
	return invoke_rpc.call_prolog_calculator(msg=msg, options=options)


def run_last_request_outside_of_docker(self):
	"""
	you should run this script from server_root/
	you should also have `services` running on the host (it doesnt matter that it's simultaneously running in docker), because they have to access files by the paths that `workers` sends them.
	"""
	tmp_volume_data_path = '/var/lib/docker/volumes/robust_tmp/_data/'
	os.system('sudo chmod -R o+rX '+shlex.quote(tmp_volume_data_path))
	last_request_host_path = tmp_volume_data_path + os.path.split(os.readlink(tmp_volume_data_path+'last_request'))[-1]
	local_calculator(last_request_host_path)



print(local_calculator.fn)
remoulade.declare_actors([local_rpc, local_calculator])






"""
>> #PP='' DISPLAY='' RABBITMQ_URL='localhost:5672' REDIS_HOST='redis://localhost' AGRAPH_HOST='localhost' AGRAPH_PORT='10035' REMOULADE_PG_URI='postgresql://remoulade@localhost:5433/remoulade' REMOULADE_API='http://localhost:5005' SERVICES_URL='http://localhost:17788' CSHARP_SERVICES_URL='http://localhost:17789' FLASK_DEBUG='0' FLASK_ENV='production' WATCHMEDO='' ./run_last_request_in_docker_with_host_fs.py --dry_run True --request /app/server_root/tmp/1691798911.3167622.57.1.A52CC96x3070
"""

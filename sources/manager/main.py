#!/usr/bin/env python3

import os, sys

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))

from tasking import remoulade



# ┏━┓┏━┓╻ ╻   ┏━┓┏━┓┏━╸
# ┣┳┛┣━┫┃╻┃   ┣┳┛┣━┛┃
# ╹┗╸╹ ╹┗┻┛   ╹┗╸╹  ┗━╸


def call_remote_rpc_job(msg, queue='default'):
	return local_rpc.send_with_options(kwargs={'msg':msg}, queue_name=queue)

@remoulade.actor(alternative_queues=["health"])
def local_rpc(msg, options=None):
	return invoke_rpc.call_prolog(msg, options)




# ┏━╸┏━┓╻  ┏━╸╻ ╻╻  ┏━┓╺┳╸┏━┓┏━┓
# ┃  ┣━┫┃  ┃  ┃ ┃┃  ┣━┫ ┃ ┃ ┃┣┳┛
# ┗━╸╹ ╹┗━╸┗━╸┗━┛┗━╸╹ ╹ ╹ ┗━┛╹┗╸

def trigger_remote_calculator_job(**kwargs):
	return local_calculator.send_with_options(kwargs=kwargs)

@remoulade.actor(time_limit=1000*60*60*24*365*1000)
def local_calculator(
	request_directory: str,
	public_url='http://localhost:8877',
	worker_options=None,
	request_format=None
):
	msg = dict(
		method='calculator',
		params=dict(
			request_format=request_format,
			request_tmp_directory_name = request_directory,
			request_files = convert_request_files(files_in_dir(get_tmp_directory_absolute_path(request_directory))),
			public_url = public_url
		)
	)
	update_last_request_symlink(request_directory)
	return invoke_rpc.call_prolog_calculator(msg=msg, worker_options=worker_options)




#print(local_calculator.fn)
remoulade.declare_actors([local_rpc, local_calculator])






app = FastAPI(
	title="Robust API",
	summary="invoke accounting calculators and other endpoints",
	servers = [dict(url=os.environ['PUBLIC_URL'][:-1])],

)


from dotdict import Dotdict

remoulade_worker_args = Dotdict(dict(
	modules=[],
	queues=['default'],
	threads=1,
	prefetch_multiplier=1))

print(start_worker(remoulade_worker_args, logging.get_logger('remoulade')))




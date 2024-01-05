"""

frontend (or other caller) imports this file.

"""
import time

import remoulade

def call_remote_rpc_job(msg, queue='default'):
	return local_rpc.send_with_options(kwargs={'msg':msg}, queue_name=queue)
@remoulade.actor(alternative_queues=["health"])
def local_rpc(msg, options=None):
	return call_prolog(msg, options)

def trigger_remote_calculator_job(**kwargs):
	return local_calculator.send_with_options(kwargs=kwargs)
@remoulade.actor(time_limit=1000*60*60*24*365*1000)
def local_calculator(
	request_directory: str,
	public_url='http://localhost:8877',
	worker_options=None,
	request_format=None
):

	# this is gonna call out to workers and wait for them to finish. But even more properly,
	# local_calculator actor should be composed with convert_request_file actors, and the whole pipeline should be managed on remoulade level, with retries and everything. Here, if prolog fails, we'll be redoing the conversions too, and there'll be no visibility into it.

	converted_request_files = convert_request_files(files_in_dir(get_tmp_directory_absolute_path(request_directory)))

	msg = dict(
		method='calculator',
		params=dict(
			request_format=request_format,
			request_tmp_directory_name = request_directory,
			request_files = converted_request_files,
			public_url = public_url
		)
	)

	# for trusted workers, we can keep the tmp dir logic as is. Tmp dir is created inside worker, etc.
	# but for untrusted workers, the machine will be started with request files (somehow), and we'll need to fetch the results from the machine when it's done. We can still stick to the shared volume etc, but we have to create the tmp dir here on manager, and copy the files to the machine, and fetch back the result, and symlink from final_result here..
	# i can eventually see the "calculator" function being completely collapsed from worker into manager here.

	update_last_request_symlink(request_directory)

	return do_job(dict(
		proc='call_prolog_calculator',
		msg=msg,
		worker_options=worker_options))


def _call_prolog(msg, options):
	return do_job(dict(
		msg=msg,
		options=options
	))


remoulade.declare_actors([local_rpc, local_calculator])

import subprocess
import sys, os
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tmp_dir_path import get_tmp_directory_absolute_path
import invoke_rpc


def call_prolog_calculator(final_result_tmp_directory_name, final_result_tmp_directory_path, server_url, request_tmp_directory_name, request_files, request_format=None, **kwargs):

	msg = {	"method": "calculator",
			"params": {
				'request_format': request_format,
				"server_url": server_url,
				"request_files": request_files,
				"request_tmp_directory_name": request_tmp_directory_name,
				"final_result_tmp_directory_name": final_result_tmp_directory_name,
				"final_result_tmp_directory_path": final_result_tmp_directory_path,
			}
   }

	update_last_request_symlink(msg)

	kwargs.update({
		'msg': msg,
	})
	#
	# if celery_app:
	# 	task = celery_app.signature('invoke_rpc.call_prolog_calculator2').apply_async(kwargs=kwargs)
	# 	return task.get(timeout=timeout_seconds)['response_tmp_directory_name']
	# else:
	# 	from invoke_rpc import call_prolog_calculator2
	# 	return call_prolog_calculator2(**kwargs)['response_tmp_directory_name']


	# task = celery_app.signature('invoke_rpc.call_prolog_calculator2').apply_async(kwargs=kwargs)
	# return task.get(timeout=timeout_seconds)['response_tmp_directory_name']

	return invoke_rpc.call_prolog_calculator2.send(kwargs=kwargs).result


def update_last_request_symlink(msg):
	subprocess.call(['/bin/rm', get_tmp_directory_absolute_path('last_request')])
	subprocess.call([
		'/bin/ln', '-s',
		# get_tmp_directory_absolute_path(msg['params']['request_tmp_directory_name']), #<- absolute
		(msg['params']['request_tmp_directory_name']),  # <- relative
		get_tmp_directory_absolute_path('last_request')
	])

import subprocess
import sys, os
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tmp_dir_path import get_tmp_directory_absolute_path

def call_prolog_calculator(celery_app, final_result_tmp_directory_name, server_url, request_tmp_directory_name, request_files, timeout_seconds=0, **kwargs):

	msg = {	"method": "calculator",
			"params": {
				"server_url": server_url,
				"request_files": request_files,
				"request_tmp_directory_name": request_tmp_directory_name
			}
   }

	#print('msg:')
	#print(msg)

	subprocess.call(['/bin/rm', get_tmp_directory_absolute_path('last_request')])
	subprocess.call([
		'/bin/ln', '-s',
		#get_tmp_directory_absolute_path(msg['params']['request_tmp_directory_name']), #<- absolute
		(msg['params']['request_tmp_directory_name']), #<- relative
		get_tmp_directory_absolute_path('last_request')
	])

	kwargs.update({
		"final_result_tmp_directory_name": final_result_tmp_directory_name,
		'msg': msg
		})

	if celery_app:
		task = celery_app.signature('invoke_rpc.call_prolog').apply_async(kwargs=kwargs)
		response_tmp_directory_name, _result_json = task.get(timeout=timeout_seconds)
	else:
		from invoke_rpc import call_prolog
		response_tmp_directory_name, _result_json = call_prolog(**kwargs)
	return response_tmp_directory_name


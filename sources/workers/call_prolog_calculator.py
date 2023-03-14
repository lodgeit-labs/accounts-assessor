import subprocess
import sys, os
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tmp_dir_path import get_tmp_directory_absolute_path
import invoke_rpc


def call_prolog_calculator(final_result_tmp_directory_name, final_result_tmp_directory_path, server_url, request_tmp_directory_name, request_files, request_format=None, **kwargs):
	"""
	this is a wrapper to call_prolog_calculator2.
	this is called synchronously from frontend code or from cli code.
	"""

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

	return invoke_rpc.call_prolog_calculator2.send(kwargs=kwargs)


def update_last_request_symlink(msg):
	subprocess.call(['/bin/rm', get_tmp_directory_absolute_path('last_request')])
	subprocess.call([
		'/bin/ln', '-s',
		# get_tmp_directory_absolute_path(msg['params']['request_tmp_directory_name']), #<- absolute
		(msg['params']['request_tmp_directory_name']),  # <- relative
		get_tmp_directory_absolute_path('last_request')
	])

import subprocess
import sys, os
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tmp_dir_path import get_tmp_directory_absolute_path
import invoke_rpc


def create_calculator_job(server_url, request_tmp_directory_name, request_files, request_format=None, **kwargs):
	"""
	this is a wrapper to call_prolog_calculator2.
	this is called synchronously from frontend code or from cli code.
	"""

	msg = {	"method": "calculator",
			"params": {
				'request_format': request_format,
				"server_url": server_url,
				"request_files": request_files, # request files list
				"request_tmp_directory_name": request_tmp_directory_name, # request files directory
			}
   }

	update_last_request_symlink(msg)
	job = invoke_rpc.call_prolog_calculator2.send(kwargs=kwargs | msg)
	logger.info('job.message_id: %s' % job.message_id)
	return job


def update_last_request_symlink(msg):
	subprocess.call([
		'/bin/ln', '-s',
		msg['params']['request_tmp_directory_name'],
		msg['params']['request_tmp_directory_name'] + '/last_request',
	])
	subprocess.call([
		'/bin/mv',
		msg['params']['request_tmp_directory_name'] + '/last_request',
		get_tmp_directory_absolute_path('last_request')
	])

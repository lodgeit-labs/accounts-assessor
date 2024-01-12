"""

frontend (or other caller) imports this file.

"""
import logging
import time
from pathlib import Path

from fs_utils import files_in_dir
from tasking import remoulade
from tmp_dir_path import get_tmp_directory_absolute_path, symlink, create_tmp_for_user, ln
from untrusted_job import *
from helpers import *






def trigger_remote_prolog_rpc_job(msg, queue='default'):
	return local_rpc.send_with_options(kwargs={'msg':msg}, queue_name=queue)

def trigger_remote_prolog_calculator_job(**kwargs):
	return local_calculator.send_with_options(kwargs=kwargs)








@remoulade.actor(alternative_queues=["health"])
def local_rpc(msg, worker_options=None):	
	return do_untrusted_job(dict(
		proc='call_prolog',
		msg=msg,
		worker_options=worker_options
	))



	
@remoulade.actor(time_limit=1000*60*60*24*365*1000)
def local_calculator(
	request_directory: str,
	public_url='http://localhost:8877',
	worker_options=None,
	request_format=None
):
	
	# create a tmp directory for results files created by this invocation of the calculator
	result_tmp_directory_name, result_tmp_directory_path = create_tmp_for_user(worker_options['user'])
	# potentially convert request files to rdf (this invokes other actors)
	converted_request_files = convert_request_files(files_in_dir(get_tmp_directory_absolute_path(request_directory)))

	# the params that will be passed to the prolog calculator
	params=dict(
		request_files = converted_request_files,
		request_format=request_format,
		request_tmp_directory_name = request_directory,
		result_tmp_directory_name= result_tmp_directory_name,
		public_url = public_url
	)


	# ensure the job directory exists. You'd expect this done by the caller, but it doesn't hurt to do it here.
	params['final_result_tmp_directory_name'] = CurrentMessage.get_current_message().message_id
	if params['final_result_tmp_directory_name'] is None:
		params['final_result_tmp_directory_name'] = 'cli'
	params['final_result_tmp_directory_path'] = get_tmp_directory_absolute_path(params['final_result_tmp_directory_name'])
	Path(params['final_result_tmp_directory_path']).mkdir(parents=True, exist_ok=True)


	# only useful in single-user use, but still useful:
	symlink('last_request', request_directory)
	symlink('last_result', result_tmp_directory_name)


	# more reproducibility:
	copy_repo_status_txt_to_result_dir(result_tmp_directory_path)
	
	
	# establish a relation from job to calculator result directory, basically to this attempt to complete the job.
	ln('../'+result_tmp_directory_name, params['final_result_tmp_directory_path'] + '/' + result_tmp_directory_name)


	result = do_untrusted_job(dict(
		proc='call_prolog_calculator',
		params=params,
		worker_options=worker_options))


	# mark this calculator result as finished, and the job as completed
	ln('../' + result_tmp_directory_name, params['final_result_tmp_directory_path'] + '/completed')

	
	return return
	


def convert_request_files(files):
	return list(filter(None, map(convert_request_file0, files)))

def convert_request_file0(file):
	logging.getLogger().info('convert_request_file?: %s' % file)

	if file.endswith('/.htaccess'):
		return None
	if file.endswith('/request.json'):
		return None # effectively hide the file from further processing
	if file.endswith('/request.xml'):
		converted_dir = make_converted_dir(file)
		converted_file = Xml2rdf().xml2rdf(file, converted_dir)
		if converted_file is not None:
			return converted_file
	if file.lower().endswith('.xlsx'):
		converted_dir = make_converted_dir(file)
		converted_file = str(converted_dir.joinpath(str(PurePath(file).name) + '.n3'))
		convert_excel_to_rdf(file, converted_file)
		return converted_file
	else:
		return file








	return convert_request_file.send(file).get()

@remoulade.actor(alternative_queues=["utils"])
def convert_request_file(tmp, f):

	return do_untrusted_job(dict(
		proc='convert_request_file',
		msg=dict(
				request_file=f,
				request_tmp_directory_name=tmp
			)
		)
	))



remoulade.declare_actors([local_rpc, local_calculator, convert_request_file])



from fs_utils import files_in_dir









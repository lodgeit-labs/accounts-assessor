"""

frontend (or other caller) imports this file.

"""

import logging, sys
from pathlib import Path

from fs_utils import files_in_dir
from tasking import remoulade
from tmp_dir_path import get_tmp_directory_absolute_path, symlink, ln
from tmp_dir import create_tmp_for_user
from app.untrusted_task import *
from app.helpers import *

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/sdk/src/')))
import robust_sdk.xml2rdf


def trigger_remote__call_prolog(msg, queue='default'):
	return call_prolog.send_with_options(kwargs={'msg':msg}, queue_name=queue)

def trigger_remote__call_prolog_calculator(**kwargs):
	return call_prolog_calculator.send_with_options(kwargs=kwargs)




@remoulade.actor(alternative_queues=["health"])
def call_prolog(msg, worker_options=None):	
	return do_untrusted_task(Task(
		proc='call_prolog',
		args=dict(msg=msg),
		worker_options=worker_options
	))



	
@remoulade.actor(time_limit=1000*60*60*24*365*1000)
def call_prolog_calculator(
	request_directory: str,
	public_url='http://localhost:8877',
	worker_options=None,
	request_format=None,
	xlsx_extraction_rdf_root="ic_ui:investment_calculator_sheets"
):
	

	# create a tmp directory for results files created by this invocation of the calculator
	result_tmp_directory_name, result_tmp_directory_path = create_tmp_for_user(worker_options['user'])
	# potentially convert request files to rdf (this invokes other actors)
	converted_request_files = preprocess_request_files(files_in_dir(get_tmp_directory_absolute_path(request_directory)), xlsx_extraction_rdf_root)


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


	result = do_untrusted_task(Task(
		proc='call_prolog_calculator',
		args=dict(params=params),
		worker_options=worker_options,
		input_paths=[get_tmp_directory_absolute_path(request_directory), result_tmp_directory_path],
		output_paths=[result_tmp_directory_path]
	))


	# mark this calculator result as finished, and the job as completed
	ln('../' + result_tmp_directory_name, params['final_result_tmp_directory_path'] + '/completed')

	
	return result
	


def preprocess_request_files(files, xlsx_extraction_rdf_root):
	return list(filter(None, map(preprocess_request_file(xlsx_extraction_rdf_root), files)))

def preprocess_request_file(file, xlsx_extraction_rdf_root):
	logging.getLogger().info('convert_request_file?: %s' % file)

	if file.endswith('/.htaccess'):
		return None # hide the file from further processing
	if file.endswith('/request.json'):
		return None
		
	if file.endswith('/request.xml'):
		converted_dir = make_converted_dir(file)
		converted_file = xml2rdf.Xml2rdf().xml2rdf(file, converted_dir)
		if converted_file is not None:
			return converted_file
			
	if file.lower().endswith('.xlsx'):
		converted_dir = make_converted_dir(file)
		converted_file = str(converted_dir.joinpath(str(PurePath(file).name) + '.n3'))
		convert_excel_to_rdf(file, converted_file, root=xlsx_extraction_rdf_root)
		return converted_file
	
	return file


def convert_excel_to_rdf(uploaded, to_be_processed, root):
	"""run a POST request to csharp-services to convert the file.
	We should really turn csharp-services into an untrusted worker at some point.	
	"""
	logging.getLogger().info('xlsx_to_rdf: %s -> %s' % (uploaded, to_be_processed))
	requests.post(os.environ['CSHARP_SERVICES_URL'] + '/xlsx_to_rdf', json={"root": root, "input_fn": str(uploaded), "output_fn": str(to_be_processed)}).raise_for_status()





remoulade.declare_actors([call_prolog, call_prolog_calculator])

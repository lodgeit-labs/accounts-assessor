"""

frontend (or other caller) imports this file.

"""

import logging, sys
from pathlib import Path

import requests, time

from agraph import repo_by_user
from fs_utils import files_in_dir
from tasking import remoulade
from tmp_dir_path import get_tmp_directory_absolute_path, symlink, ln
from tmp_dir import create_tmp_for_user, create_tmp
from app.untrusted_task import *
from app.helpers import *

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/sdk/src/')))
import robust_sdk.xml2rdf

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../actors/')))

#import tasking
import trusted_workers
#tasking.remoulade.set_broker(tasking.broker)


# def trigger_remote__call_prolog(msg, queue='default'):
# 	log.debug('trigger_remote__call_prolog: ...')
# 	return call_prolog.send_with_options(kwargs={'msg':msg}, queue_name=queue)

# def trigger_remote__call_prolog_calculator(**kwargs):
# 	log.debug('trigger_remote__call_prolog_calculator: ...')
# 	return call_prolog_calculator.send_with_options(kwargs=kwargs)



log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.debug("debug from manager_actors.py")



@remoulade.actor(alternative_queues=["health"], priority=1)
def call_prolog_rpc(msg, worker_options=None):
	log.debug('manager_actors: call_prolog: ...')
	return do_untrusted_task(Task(
		proc='call_prolog',
		args=dict(
			msg=msg, 
			worker_tmp_directory_name=create_tmp('rpc', exist_ok=True)[0]
		),
		worker_options=worker_options,
		input_files=[],
		output_path=None
	))


	
@remoulade.actor(time_limit=1000*60*60*24*365*1000)
def call_prolog_calculator(
	request_directory: str,
	public_url='http://localhost:8877',
	worker_options=None,
	request_format=None,
	xlsx_extraction_rdf_root="ic_ui:investment_calculator_sheets"
):
	log.debug('manager_actors: call_prolog_calculator(%s, %s, %s, %s, %s)' % (request_directory, public_url, worker_options, request_format, xlsx_extraction_rdf_root))

	# create a tmp directory for results files created by this invocation of the calculator
	result_tmp_directory_name, result_tmp_directory_path = create_tmp_for_user(worker_options['user'])
	
	# create symlink to inputs 
	#ln('../'+request_directory, result_tmp_directory_path + '/inputs')
	
	# potentially convert request files to rdf (this invokes other actors)
	converted_request_files = preprocess_request_files(files_in_dir(get_tmp_directory_absolute_path(request_directory)), xlsx_extraction_rdf_root)


	# the params that will be passed to the prolog calculator
	params=dict(
		request_files = converted_request_files,
		request_format=request_format,
		request_tmp_directory_name=request_directory,
		result_tmp_directory_name=result_tmp_directory_name,
		public_url=public_url,
		rdf_explorer_bases=[os.environ['AGRAPH_URL'] + '/classic-webview#/repositories/'+repo_by_user(worker_options['user'])+'/node/'] 
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
	
	
	# establish a relation from job to calculator result directory
	ln('../'+result_tmp_directory_name, params['final_result_tmp_directory_path'] + '/' + result_tmp_directory_name)


	result = do_untrusted_task(Task(
		proc='call_prolog',
		args=dict(
			msg=dict(
				method='calculator', 
				params=params
			),
			worker_tmp_directory_name=result_tmp_directory_name
		),
		worker_options=worker_options,
		input_files=converted_request_files,
		output_path=result_tmp_directory_path,		
	))


	# mark this calculator result as finished, and the job as completed
	ln('../' + result_tmp_directory_name, params['final_result_tmp_directory_path'] + '/completed')

	
	log.info('postprocess(%s, %s, %s)' % (result_tmp_directory_path, result.get('uris'), worker_options['user']))
	trusted_workers.postprocess.send_with_options(kwargs=dict(
		job=params['final_result_tmp_directory_name'],
		request_directory=request_directory,
		tmp_name=result_tmp_directory_name,
		tmp_path=result_tmp_directory_path,
		uris=result.get('uris'),
		user=worker_options['user']
	), queue_name='postprocessing')

	return result



def preprocess_request_files(files, xlsx_extraction_rdf_root):
	got_rdf = False
	for file in files:
		if file.lower().endswith('.n3'):
			got_rdf = True
	if got_rdf:
		for i,file in enumerate(files):
			if file.lower().endswith('.xlsx'):
				files[i] = None
				break
	return list(filter(None, map(lambda f: preprocess_request_file(xlsx_extraction_rdf_root, f), files)))

def preprocess_request_file(xlsx_extraction_rdf_root, file):
	log.info('convert_request_file?: %s' % file)

	if file is None:
		return None
	if file.endswith('/.access'):
		return None # hide the file from further processing
	if file.endswith('/.htaccess'):
		return None # hide the file from further processing
	if file.endswith('/request.json'):
		return None
		
	if file.endswith('/request.xml'):
		converted_dir = make_converted_dir(file)
		converted_file = robust_sdk.xml2rdf.Xml2rdf().xml2rdf(file, converted_dir)
		if converted_file is not None:
			log.info('converted_file: %s' % converted_file)
			return converted_file
			
	if file.lower().endswith('.xlsx'):
		converted_dir = make_converted_dir(file)
		converted_file = str(converted_dir.joinpath(str(PurePath(file).name) + '.n3'))
		convert_excel_to_rdf(file, converted_file, root=xlsx_extraction_rdf_root)
		log.info('converted_file: %s' % converted_file)
		return converted_file
	
	return file


def convert_excel_to_rdf(uploaded, to_be_processed, root):
	"""run a POST request to csharp-services to convert the file.
	We should really turn csharp-services into an untrusted worker at some point.	
	"""
	log.info('xlsx_to_rdf: %s -> %s' % (uploaded, to_be_processed))
	start_time = time.time()
	requests.post(os.environ['CSHARP_SERVICES_URL'] + '/xlsx_to_rdf', json={"root": root, "input_fn": str(uploaded), "output_fn": str(to_be_processed)}).raise_for_status()
	log.info('xlsx_to_rdf: %s -> %s done in % seconds' % (uploaded, to_be_processed, time.time() - start_time))



remoulade.declare_actors([call_prolog_rpc, call_prolog_calculator])

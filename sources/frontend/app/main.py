import subprocess
import sys, os

import urllib3.util
from franz.openrdf.query.query import QueryLanguage
from rdflib import URIRef, Literal, BNode

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../workers')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../manager')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../actors')))
xxx = os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/misc'))
sys.path.append(xxx)




import app.manager_actors as manager_actors



from json import JSONDecodeError
import json

class CustomJSONEncoder(json.JSONEncoder):
	def default(self, obj):
		try:
			return super().default(obj)
		except Exception:
			return str(obj)


from fastapi.encoders import jsonable_encoder
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware


from pathlib import PosixPath
import dateutil.parser
import logging
import os, sys
import urllib
import json
import datetime
from datetime import date
import ntpath
import shutil
import re
from pathlib import Path as P

import requests

from typing import Optional, Any, List, Annotated
from fastapi import FastAPI, Request, File, UploadFile, HTTPException, Form, status, Query, Header

from fastapi.exceptions import RequestValidationError
from fastapi.responses import PlainTextResponse, JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.responses import RedirectResponse, PlainTextResponse, HTMLResponse
from pydantic import BaseModel
from fastapi.templating import Jinja2Templates


from xml.etree import ElementTree
from xml.dom import minidom
from xml.dom.minidom import getDOMImplementation
impl = getDOMImplementation()


templates = Jinja2Templates(directory="templates")


from fs_utils import directory_files, find_report_by_key
from tmp_dir import create_tmp_for_user, get_unique_id
from tmp_dir_path import get_tmp_directory_absolute_path, ln
from auth_fastapi import get_user
import agraph, rdflib




from loguru import logger
class InterceptHandler(logging.Handler):
	def emit(self, record):
		# Get corresponding Loguru level if it exists.
		try:
			level = logger.level(record.levelname).name
		except ValueError:
			level = record.levelno

		# Find caller from where originated the logged message.
		frame, depth = sys._getframe(6), 6
		while frame and frame.f_code.co_filename == logging.__file__:
			frame = frame.f_back
			depth += 1

		logger.opt(depth=depth, exception=record.exc_info).log(level, record.getMessage())
#logging.basicConfig(handlers=[InterceptHandler()], level=0, force=True)
logger.remove()
logger.add(sys.stderr, format="{time} {level} {message}", level="DEBUG", backtrace=True, diagnose=True)



# logger = logging.getLogger(__name__)
# logger.setLevel(logging.DEBUG)
# 
# # set root logger level to DEBUG and output to console
# ch = logging.StreamHandler()
# 
# # create formatter
# formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
# 
# # add formatter to ch
# ch.setFormatter(formatter)
# 
# # add ch to logger
# logger.addHandler(ch)




class UploadedFileException(Exception):
	pass


class ChatRequest(BaseModel):
	type: str
	current_state: list[Any]

class RpcCommand(BaseModel):
	method: str
	params: Any





app = FastAPI(
	title="Robust API",
	summary="invoke accounting calculators and other endpoints",
	servers = [dict(url=os.environ['PUBLIC_URL'][:-1])],
	
)




app.add_middleware(
    CORSMiddleware,
    allow_origin_regex='http://localhost:.*',
    allow_credentials=True,
    allow_methods=["GET"],
    allow_headers=["*"],
)



@app.get("/")
def index():
	return "ok"

@app.get("/health")
def index():
	return "ok"




@app.get("/api/rdftab")
def get(request: Request, uri: str):
	"""
	render a page displaying all triples for a given URI.
	add a link to gruff or other rdf visualization tools.
	
	format the triples such that the uri is the subject, and the triple is "reversed" if needed.
	sort by importance (some hardcoded predicates go first)
	
	use rdfs:label where available
	
	where the node is a report_entry, add a link to the report.
	where the value has_crosscheck, render the whole crosscheck including both values.
	
	maybe:
	where the value is a string that refers to an account, add a link to the account URI.
	where the node is a vector, display it meaningfully.	
	"""

	user = get_user(request)
	
	result = dict(props=[])
	result['conn'] = agraph.agc(agraph.repo_by_user(user))
	
	queryString = """
	SELECT ?s ?p ?o ?g {
  
			{
              GRAPH ?g { 
				?x ?p ?o .
              }
			} UNION {
              GRAPH ?g { 
				?s ?p ?x .
              }
			}
	} LIMIT 10000
	"""
	tupleQuery: agraph.TupleQuery = result['conn'].prepareTupleQuery(QueryLanguage.SPARQL, queryString)
	tupleQuery.setBinding("x", agraph.URI(uri))
	
	logger.info(f"{uri=}")
	logger.info(f"tupleQuery.evaluate() ...")

	# too many namespaces could be a problem, but it might also be a problem for gruff etc, and so might also be too much data in a single repository.
	# So, there might be some need to manage repositories and active namespaces, and they might best be scoped to a single user by default, "pub" being a special case managed by us.
	result['namespaces'] = result['conn'].getNamespaces()
	
	results: agraph.TupleQueryResult
	with tupleQuery.evaluate() as results:
	
		for bindingSet in results:
			s = bindingSet.getValue("s")
			p = bindingSet.getValue("p")
			o = bindingSet.getValue("o")
			g = bindingSet.getValue("g")
			
			logger.info(f"{s} {p} {o} {g}")

			s2 = dict(node=s)
			p2 = dict(node=p)
			o2 = dict(node=o)
			g2 = dict(node=g)

			if s is None:
				result['props'].append(dict(p=p2, o=o2, g=g2))
			elif o is None:
				p2['reverse'] = True
				result['props'].append(dict(p=p2, o=s2, g=g2))
				
	for prop in result['props']:
		xnode_str(result, prop['p'])
		xnode_str(result, prop['o'])
		xnode_str(result, prop['g'])

	result['term'] = dict(node=agraph.franz.openrdf.model.value.URI(uri))
	xnode_str(result, result['term'])
	

	del result['conn']
	result['tools'] = [
		dict(
			label='agraph classic-webview',
			 url=os.environ['AGRAPH_URL'] + '/classic-webview#/repositories/'+agraph.repo_by_user(get_user(request))+'/node/' + '<' + uri + '>'),
		dict(
			label='sparklis (as subject)',
			url='http://www.irisa.fr/LIS/ferre/sparklis/' + urllib.parse.urlencode({
				'title': 'Hi',
				'endpoint': 'http://servolis.irisa.fr/dbpedia/sparql',
				'sparklis-query': f'[VId]Return(Det(Term(URI("{uri}")),Some(Triple(S,Det(An(7,Modif(Select,Unordered),Thing),None),Det(An(8,Modif(Select,Unordered),Thing),None)))))',
				'sparklis-path': 'DDDR'})
		),
		dict(
			label='sparklis (as object)',
			url='http://www.irisa.fr/LIS/ferre/sparklis/' + urllib.parse.urlencode({
				'title': 'Hi',
				'endpoint': 'http://servolis.irisa.fr/dbpedia/sparql',
				'sparklis-query': f'[VId]Return(Det(Term(URI("{uri}")),Some(Triple(O,Det(An(7,Modif(Select,Unordered),Thing),None),Det(An(8,Modif(Select,Unordered),Thing),None)))))',
				'sparklis-path': 'DDDR'})								 
		),
	]
	
	
	result = json.dumps(result, cls=CustomJSONEncoder, indent=4)
	#logger.info(f"{result=}")
	sys.stdout.write(result)
	return Response(media_type="application/json", content=result.encode('utf-8'))


	
def xnode_str(result,n):
	xnode_str2(result, n)
	if n.get('reverse'):
		n['short'] = f"is {n['short']} of"




def xnode_str2(result, xn):
	n = xn.get('node')
	logger.info(f"{type(n)=}")
	if isinstance(n, agraph.franz.openrdf.model.literal.Literal):
		s = n.getLabel()
		if len(s) > 100:
			s = s[:100] + '...'
		xn['literal_str'] = s
		xn['datatype'] = n.getDatatype()
		xn['language'] = n.getLanguage()
		xn['n3'] = str(n)
		
	if isinstance(n, agraph.franz.openrdf.model.value.URI):
		xn['uri'] = n.getURI()
		add_uri_labels(result, xn)
		add_uri_shortening(result, xn)



def add_uri_shortening(result,xnode):
	uri = xnode['uri']
	
	r = uri
	for k,v in result['namespaces'].items():
		if uri.startswith(v):
			rr = k + ':' + uri[len(v):]
			if len(rr) < len(r):
				r = rr
	
	xnode['short'] = r
	


def add_uri_labels(result, xn):
	labels = []
	
	queryString = """
	SELECT ?l ?g 
	{
  			{
              GRAPH ?g { 
				?s rdfs:label ?l .
              }
			}
	} LIMIT 10000
	"""
	tupleQuery: agraph.TupleQuery = result['conn'].prepareTupleQuery(QueryLanguage.SPARQL, queryString)
	tupleQuery.setBinding("s", xn['node'])
	results: agraph.TupleQueryResult
	with tupleQuery.evaluate() as results:	
		for bindingSet in results:
			labels.append(dict(str=bindingSet.getValue("l"), g=bindingSet.getValue("g")))

	if len(labels) > 0:
		xn['label'] = labels[0]
		xn['other_labels'] = labels[1:]
	else:
		xn['label']=False


def add_uri_comments(result, xn):
	labels = []
	
	queryString = """
	SELECT ?l ?g 
	{
  			{
              GRAPH ?g { 
				?s rdfs:comment ?l .
              }
			}
	} LIMIT 10000
	"""
	tupleQuery: agraph.TupleQuery = result['conn'].prepareTupleQuery(QueryLanguage.SPARQL, queryString)
	tupleQuery.setBinding("s", xn['node'])
	results: agraph.TupleQueryResult
	with tupleQuery.evaluate() as results:	
		for bindingSet in results:
			labels.append(dict(str=bindingSet.getValue("l"), g=bindingSet.getValue("g")))

	if len(labels) > 0:
		xn['comment'] = labels[0]
		xn['other_comments'] = labels[1:]
	else:
		xn['comment']=False
		
				

#@app.get("/status")
#some status page for the whole stack here? like queue size, workers, .. 



@app.post("/health_check")
def post(request: Request):
	"""
	run an end-to-end healthcheck, internally invoking prolog chat rpc endpoint. 
	"""
	r = json_prolog_rpc_call(request, {
		"method": "chat",
		"params": {"type":"sbe","current_state":[]}
	}, queue_name=None)#'health')
	if r == {"result":{"question":"Are you a Sole trader, Partnership, Company or Trust?","state":[{"question_id":0,"response":-1}]}}:
		return "ok"
	else:
		raise HTTPException(status_code=500, detail="self-test failed")



@app.post("/chat")
def post(request: Request, body: ChatRequest):
	"""
	invoke chat endpoint
	"""
	return json_prolog_rpc_call(request, {
		"method": "chat",
		"params": body.dict(),
	})



def json_prolog_rpc_call(request, msg, queue_name=None):
	msg["client"] = request.client.host
	logger.debug('json_prolog_rpc_call: %s ...' % msg)
	job = manager_actors.call_prolog_rpc.send_with_options(kwargs=dict(msg=msg), queue_name=queue_name,
		on_failure=manager_actors.print_actor_error)
	try:
		logger.debug('waiting for result (timeout 1000 * 1000)')
		result = job.result.get(block=True, timeout=1000 * 1000)
	except manager_actors.remoulade.results.errors.ErrorStored as e:
		logger.error(str(e))
		return
	logger.debug('json_prolog_rpc_call: %s' % result)
	return result



def tmp_file_url(public_url, tmp_dir_name, fn):
	return public_url + '/tmp/' + tmp_dir_name + '/' + urllib.parse.quote(fn)



def get_public_url(request: Request):
	"""todo test"""
	return request.url.scheme + '://' + request.url.netloc



@app.get("/view/job/{job_id}", response_class=HTMLResponse)
async def views_limbo(request: Request, job_id: str, redirect:bool=True):
	"""
	job html page
	"""
	logger.debug('%s', job_id)
	job = await get_job_by_id(request, job_id)
	logger.debug('%s', job)
	
	if job is not None:
		if isinstance(job, str):
			job = dict(json=job)
		logger.debug('%s', job)

		if redirect and job.get('status') == 'Success' and 'reports' in job.get('result'):
			logger.debug('redirect.')
			return RedirectResponse(find_report_by_key(job['result']['reports'], 'task_directory'))
		else:
			mem_txt,mem_data = write_mem_stuff(job.get('message_id'))
			server_info_url = get_public_url(request) + '/static/git_info.txt'

			logger.debug('limbo.')
			
			alerts = []
			if job.get('result'):
				alerts = job['result'].get('alerts', [])

			status = job.get('status', 'unknown')
			if len(alerts) > 0:
				status = 'Alert'

			# it turns out that failures are not permanent
			return templates.TemplateResponse("job.html", {
				"server_info_url": server_info_url,
				"mem_txt": mem_txt, 
				"mem_data":mem_data, 
				"request": request, 
				"job_id": job_id, 
				"alerts": '\n'.join(alerts),
				"json": json.dumps(job, indent=4, sort_keys=True), 
				"refresh": (job.get('status') not in [ 'Success']), 
				'status': status})
	
	else:
		return PlainTextResponse(f'job {job_id=} not found', status_code=404)	
	


def write_mem_stuff(message_id):
	if message_id is None:
		return '',[]
	else:
		mem_txt = ''
		files = []
		for f in P(get_tmp_directory_absolute_path(message_id)).glob('*/mem_prof.txt'):
			if str(f).endswith('/completed/mem_prof.txt'):
				continue
			files.append(f)
		files.sort(key=lambda f: f.stat().st_mtime)

		for f in files:
			logger.info('f: %s' % f)
			with open(f) as f2:
				mem_txt += f2.read()

		#logger.info(mem_txt)
		mem_data = []
		
		mmm = mem_txt.splitlines()

		for line in mmm:
			if line.startswith('MEM '):
				#logger.info(line)
				mem = float(line.split()[1])
				ts = float(line.split()[2])
				mem_data.append(dict(x=ts*1000,y=mem))
		return mem_txt,mem_data



def calculator_job_by_id(id: str):
	id = re.sub(r'[^a-zA-Z0-9_\-\.]', '', id)
	r = requests.get(os.environ['REMOULADE_API'] + '/messages/states/' + id)
	if not r.ok:
		return None
	message = r.json()
	if message['actor_name'] not in ["call_prolog_calculator"]:
		return None
	#logger.info('job: %s' % message)
	enrich_job_json_with_duration(message)
	enrich_job_json_with_result(message)
	return message



def enrich_job_json_with_result(message):
	# a dict with either result or error key (i think...)
	result = requests.get(os.environ['REMOULADE_API'] + '/messages/result/' + message['message_id'], params={'max_size':'99999999'#'raise_on_error':False # this is ignored
	})
	try:
		result = result.json()
	except Exception as e:
		logger.warning('nonsense received from remoulade api:')
		logger.warning('result: %s' % result.text)
		logger.warning('error: %s' % e)

	if 'result' in result:
		try:
			message['result'] = json.loads(result['result'])
		except JSONDecodeError:
			message['result'] = result['result']
	else:
		message['result'] = {}



@app.get('/api/job/{id}')
async def get_job_by_id(request: Request, id: str):
	"""
	get job json
	"""
	user = get_user(request)
	message = calculator_job_by_id(id)
	if message is None:
		raise HTTPException(status_code=404, detail=f'job {id=} not found')
		#return PlainTextResponse(f'job {id=} not found', status_code=404)
	logger.info('job: %s' % message)
	
	# check auth
	job_user = message.get('kwargs', {}).get('user', None)
	if job_user is not None and job_user != user:
		r = dict(error='not authorized', job_user=job_user, user=user)
		logger.info('not authorized: %s' % r)
		return r
		
	return message



def enrich_job_json_with_duration(message):
	# '2012-05-29T19:30:03.283Z'
	# "2023-09-21T10:16:44.571279+00:00",
	enqueued_datetime = dateutil.parser.parse(message['enqueued_datetime'])
	end_datetime = message.get('end_datetime', None)
	if end_datetime is not None:
		end_datetime = dateutil.parser.parse(end_datetime)
		
		message['wait_time'] = str(end_datetime - enqueued_datetime)
	
		started_datetime = message.get('started_datetime', None)
		if started_datetime is not None:
			started_datetime = dateutil.parser.parse(started_datetime)
			message['duration'] = str(end_datetime - started_datetime)



@app.post("/reference")
def reference(request: Request, fileurl: str = Form(...)):#: Annotated[str, Form()]):
	"""
	Trigger a calculator by submitting an URL of an input file.
	"""
	# todo, we should probably instead implement this as a part of "preprocessing" the uploaded content, that is, there'd be a "reference" type of "uploaded file", and the referenced url should then also be retrieved in a unified way along with retrieving for example xbrl taxonomies referenced by xbrl files.

	url = urllib.parse.urlparse(fileurl)
	netloc = url.netloc
	logger.info('/reference url: ' + str(url))
	logger.info('netloc: ' + str(netloc))

	if not netloc.endswith(".files.1drv.com"):
		return {"error": "only onedrive urls are allowed at this time"}
		# we should be able to loosen this up now that we have a proxy in place

	request_tmp_directory_name, request_tmp_directory_path = create_tmp_for_user(get_user(request))

	_fn = file_download(fileurl, request_tmp_directory_path, 'file1.xlsx')
	logger.info('fn: %s' % _fn)
	
	r = process_request(request, request_tmp_directory_name, request_tmp_directory_path)[1]
	
	job_view_url = find_report_by_key(r['reports'], 'job_view_url')
	if job_view_url is not None:
		return RedirectResponse(job_view_url, status_code=status.HTTP_303_SEE_OTHER)

	return r



def file_download(url, dir, filename_hint=None, disallowed_filenames=['.htaccess', 'request.json']):
	"""
	here we could call out to an actor (potentially inside an untrusted worker) with the same functionality, but this
	1) seems unnecessary, as download_bastion and/or a webproxy takes care of security
	2) would add some complexity, as we'd have to (remoulade-)compose that invocation with the rest of the pipeline...
	"""
	r = requests.post(os.environ['DOWNLOAD_BASTION_URL'] + '/get_file_from_url_into_dir', json=dict(url=url, dir=dir, filename_hint=filename_hint, disallowed_filenames=disallowed_filenames))
	r.raise_for_status()
	r = r.json()
	if 'error' in r:
		raise Exception(r['error'])
	return r['filename']



@app.get("/view/upload_form")
def upload_form(request: Request):
	return templates.TemplateResponse("upload.html", {
		"public_url": get_public_url(request),
		"request": request,
	})



@app.get("/view/archive/{job}/{task_directory}")
def archive(request: Request, job: str, task_directory: str):
	message = calculator_job_by_id(job)
	public_url = get_public_url(request)
	
	# sanitize task_directory parameter, just for security
	task_directory = re.sub(r'[^a-zA-Z0-9_\-\.]', '', task_directory)
	# todo: check that it belongs to user

	if message is None:
		return PlainTextResponse(f'job {job=} not found', status_code=404)

	archive_dir_path = PosixPath(get_tmp_directory_absolute_path(job)) / 'archive'
	zip_path = archive_dir_path / f'{task_directory}.zip'
	zip_url = public_url + '/tmp/' + job + '/archive/' + task_directory + '.zip'

	if archive_dir_path.is_dir():
		if zip_path.is_file():
			return RedirectResponse(zip_url)
		else:
			return PlainTextResponse(f'archiving in progress: {archive_dir_path=} {zip_path=}')
	else:
		create_archive(task_directory, message, archive_dir_path, zip_path)
		return RedirectResponse(zip_url)



def create_archive(task_directory, message, archive_dir_path, final_zip_path):

	workdir = PosixPath(archive_dir_path / get_unique_id())
	workdir.mkdir(parents=True, exist_ok=True)
	zip_primary_fn = 'zip.zip'
	zip_primary_path = workdir / zip_primary_fn

	zip_sources_dir = workdir / task_directory
	zip_sources_dir.mkdir(parents=True, exist_ok=True)
	
	with open(zip_sources_dir / 'job.json', 'w') as f:
		json.dump(message, f, indent=4)

	# /tmp/job/archive/workdir/task_directory/inputs -> /tmp/inputs
	inputs_path_relative = '../../../../' + message['kwargs']['request_directory']
	results_path_relative = '../../../../' + task_directory

	ln(inputs_path_relative, zip_sources_dir / 'inputs')
	ln(results_path_relative, zip_sources_dir / 'results')

	cmd = dict(args=['/usr/bin/zip', '-r', zip_primary_fn, task_directory], cwd=workdir)
	logger.info('cmd: %s' % cmd)
	subprocess.check_call(**cmd)
	os.rename(zip_primary_path, final_zip_path)



@app.post("/upload")
def upload(request: Request, file1: Optional[UploadFile]=None, file2: Optional[UploadFile]=None, file3: Optional[UploadFile]=None, request_format:str='rdf', requested_output_format:str='job_handle', xlsx_extraction_rdf_root:str=None):
	"""
	Trigger a calculator by uploading one or more input files.
	"""
	
	logger.info('upload: xlsx_extraction_rdf_root: %s' % xlsx_extraction_rdf_root)
	
	request_tmp_directory_name, request_tmp_directory_path = create_tmp_for_user(get_user(request))

	for file in [file1, file2, file3]:
		if file is None:
			continue
		if file.filename == '':
			continue
		logger.info('uploaded: %s' % repr(file.filename))
		_uploaded = save_uploaded_file(request_tmp_directory_path, file)

	return process_request(request, request_tmp_directory_name, request_tmp_directory_path, request_format, requested_output_format, xlsx_extraction_rdf_root)[0]



def load_worker_options_from_request_json(request_tmp_directory_path):
	request_json = os.path.join(request_tmp_directory_path, 'request.json')
	if os.path.exists(request_json):
		with open(request_json) as f:
			options = json.load(f).get('worker_options', {})
	else:
		logger.info('no %s' % request_json)
		options = {}
	logger.info('options: %s' % str(options))
	return options



def process_request(request, request_tmp_directory_name, request_tmp_directory_path, request_format='rdf', requested_output_format = 'job_handle', xlsx_extraction_rdf_root:str=None):
	
	public_url=get_public_url(request)
	worker_options = load_worker_options_from_request_json(request_tmp_directory_path)
	worker_options['user'] = get_user(request)

	job = manager_actors.call_prolog_calculator.send_with_options(
		kwargs=dict(
			request_format=request_format,
			request_directory=request_tmp_directory_name,
			xlsx_extraction_rdf_root=xlsx_extraction_rdf_root,
			public_url=public_url,
			worker_options=worker_options
		),
		on_failure=manager_actors.print_actor_error
	)

	logger.info('requested_output_format: %s' % requested_output_format)

	# the immediate modes should be removed, they are only legacy excel plugin stuff
	if requested_output_format == 'immediate_xml':
			try:
				logger.debug('waiting for result (timeout 1000 * 1000)')
				reports = job.result.get(block=True, timeout=1000 * 1000)
			except manager_actors.remoulade.results.errors.ErrorStored as e:
				logger.error(str(e))
				return PlainTextResponse(str(e), status_code=500), str(e)
			if 'error' in reports:
				return PlainTextResponse(reports['error'], status_code=500), reports['error']
			logger.info(str(reports))
			# was this an error?
			if reports['alerts'] != []:
				if 'reports' in reports:
					taskdir = '<task_directory>' + find_report_by_key(reports['reports'], 'task_directory') + '</task_directory>'
				else:
					taskdir = '<job_id>'+job.message_id+'</job_id>'
				error_xml_text = (
						'<error>' +
						'<message>' + '. '.join(reports['alerts']) + '</message>' +
						taskdir +
						'</error>')
				return PlainTextResponse(exrror_xml_text, status_code=500), error_xml_text
			# div7a 'result' xml
			result_xml_report = find_report_by_key(reports['reports'], 'result')
			if result_xml_report is None:
				# livestock 'response' xml
				result_xml_report = find_report_by_key(reports['reports'], 'response')
			return RedirectResponse(result_xml_report), None
			
	elif requested_output_format == 'immediate_json_reports_list':
			reports = job.result.get(block=True, timeout=1000 * 1000)
			return RedirectResponse(find_report_by_key(reports['reports'], 'task_directory') + '/000000_response.json.json'), reports
			
	elif requested_output_format == 'job_handle':
		jsn = {
			"alerts": ["job scheduled."],
			"reports":
				[{
					"title": "job URL",
					"key": "job_tmp_url",
					"val": {"url": job_tmp_url(public_url, job)}},
					{
						"title": "job API URL",
						"key": "job_api_url",
						"val": {"url": public_url + '/api/job/' + job.message_id}},
					{
						"title": "job view URL",
						"key": "job_view_url",
						"val": {"url": public_url + '/view/job/' + job.message_id}},
				]
		}
		return JSONResponse(jsn), jsn
		
	else:
		raise Exception('unexpected requested_output_format')


def save_uploaded_file(tmp_directory_path, src):

	logger.info('save_uploaded_file tmp_directory_path: %s, src: %s' % (tmp_directory_path, src.filename))

	if src.filename in ['.htaccess', '.', '..', 'converted']:
		raise Exception('invalid file name')
	
	dest = os.path.abspath('/'.join([tmp_directory_path, ntpath.basename(src.filename)]))
	with open(dest, 'wb+') as dest_fd:
		shutil.copyfileobj(src.file, dest_fd)
	return dest




def create_workbook_with_template(template_uri: str):
	"""
	generate a xlsx file, and possibly just store it in tmp/.
	
	return it to client for download, or, possibly, if user is logged in with onedrive, save it to onedrive
	
	"""
	pass#todo
	
	

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
	return PlainTextResponse(str(exc), status_code=400)



def job_tmp_url(public_url, job):
	return tmp_file_url(public_url, job.message_id, '')





"""
these are separate sub-apps mainly so that they have their own openapi schema, with just what makes sense for custom gpts. It also makes it easy to experiment with different versions, simply by changing the openapi.json path inside chatgpt config. 
"""



ai3 = FastAPI(
	title="Robust API",
	summary="Invoke accounting calculators.",
	servers=[dict(url=os.environ['PUBLIC_URL']+'/ai3')],
	root_path_in_servers=False,
)



@ai3.get("/")
def index():
	return "ok"



@ai3.get('/div7a')
def div7a(
	request: Request,

	loan_year: Annotated[int, Query(
		title="The income year in which the amalgamated loan was made",
		example=2020
	)],
	full_term: Annotated[int, Query(
		title="The length of the loan, in years",
		example=7
	)],
	opening_balance: Annotated[float, Query(
		title="Opening balance of the income year given by opening_balance_year.",
		example=100000
	)],
	opening_balance_year: Annotated[int, Query(
		title="Income year of opening balance. If opening_balance_year is the income year following the income year in which the loan was made, then opening_balance is the principal amount, of the loan. If user provides principal amount, then opening_balance_year should be the year after loan_year. If opening_balance_year is not specified, it is usually the current income year. Any repayments made before opening_balance_year are ignored.",
		example=2020
	)],
	lodgement_date: Annotated[Optional[date], Query(
		title="Date of lodgement of the income year in which the loan was made. Required if opening_balance_year is loan_year.",
		example="2021-06-30"
	)],
	repayment_dates: Annotated[list[date], Query(
		example=["2021-06-30", "2022-06-30", "2023-06-30"]
	)],
	repayment_amounts: Annotated[list[float], Query(
		example=[10001, 10002, 10003]
	)],

):
	"""
	Return a breakdown, year by year, of relevant events and values of a Division 7A loan. Calculate the minimum yearly repayment, opening and closing balance, repayment shortfall, interest, and other information for each year.
	"""

	# todo, optionally create job directory if needed. This isn't much of a blocking operation, and it's done exactly the same in /upload etc.

	logging.getLogger().info(f'{loan_year=}, {full_term=}, {opening_balance=}, {opening_balance_year=}, {lodgement_date=}, {repayment_dates=}, {repayment_amounts=}')

	# now, invoke services to do the actual work.
	services_request = dict(
		request=dict(
			loan_year=loan_year,
			full_term=full_term,
			opening_balance=opening_balance,
			opening_balance_year=opening_balance_year,
			repayments=[{'date': date, 'amount': amount} for date, amount in zip(repayment_dates, repayment_amounts)],
			lodgement_date=lodgement_date
		),
		tmp_dir=list(create_tmp_for_user(get_user(request)))
	)
	r = requests.post(os.environ['SERVICES_URL'] + '/div7a2', json=jsonable_encoder(services_request))
	r.raise_for_status()
	response = r.json()
	logging.getLogger().info(response)
	return response



# @ai3.post("/process_file")
# def process_file(request: Request, file1: UploadFile):
# 	"""
# 	Trigger an accounting calculator by uploading one or more files.
# 	"""
# 	request_format = None
# 	requested_output_format:str='job_handle'
#
# 	request_tmp_directory_name, request_tmp_directory_path = create_tmp_for_user(get_user(request))
#
# 	for file in filter(None, [file1]):
# 		logger.info('uploaded: %s' % file.filename)
# 		_uploaded = save_uploaded_file(request_tmp_directory_path, file)
#
# 	return process_request(request, request_tmp_directory_name, request_tmp_directory_path, request_format, requested_output_format)[0]



app.mount('/ai3', ai3)



@ai3.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
	exc_str = f'{exc}'.replace('\n', ' ').replace('   ', ' ')
	logging.error(f"{request}: {exc_str}")
	content = {'status_code': 10422, 'message': exc_str, 'data': None}
	return JSONResponse(content=content, status_code=status.HTTP_422_UNPROCESSABLE_ENTITY)








# @csrf_exempt
# def sparql_proxy(request):
# 	if request.method == 'POST':
# 		return JsonResponse({"x":agc().executeGraphQuery(request.body)})


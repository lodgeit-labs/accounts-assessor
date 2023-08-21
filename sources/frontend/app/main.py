import os, sys
import urllib.parse
import json
import datetime
import ntpath
import shutil
import re

import requests

from typing import Optional, Any, List, Annotated
from fastapi import FastAPI, Request, File, UploadFile, HTTPException, Form
from fastapi.exceptions import RequestValidationError
from fastapi.responses import PlainTextResponse, JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.responses import RedirectResponse
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from fastapi.templating import Jinja2Templates


templates = Jinja2Templates(directory="templates")


sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../workers')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common')))
import worker



from agraph import agc
import invoke_rpc
from tasking import remoulade
from fs_utils import directory_files, find_report_by_key
from tmp_dir_path import create_tmp
import call_prolog_calculator
import logging



class UploadedFileException(Exception):
	pass


class ChatRequest(BaseModel):
	type: str
	current_state: list[Any]

class RpcCommand(BaseModel):
	method: str
	params: Any



logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# set root logger level to DEBUG and output to console
ch = logging.StreamHandler()

# create formatter
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

# add formatter to ch
ch.setFormatter(formatter)

# add ch to logger
logger.addHandler(ch)





# @csrf_exempt
# def sparql_proxy(request):
# 	if request.method == 'POST':
# 		return JsonResponse({"x":agc().executeGraphQuery(request.body)})





# not sure waht i was getting at here
# def ee(context_manager):
# 	return ExitStack().enter_context(context_manager)
#
# def secret(key):
# 	try:
# 		stack = ee(open('/run/secrets/'+key))
# 	except FileNotFoundError:
# 		pass
# 	else:
# 		with stack as f:
# 			return f.read().rstrip('\n')
# 	return os.environ[key]



app = FastAPI()


@app.get("/")
async def read_root():
	return {"Hello": "World"}


#@app.get("/health")
#some status page here?


@app.post("/health_check")
def post(request: Request):
	r = json_prolog_rpc_call(request, {
		"method": "chat",
		"params": {"type":"sbe","current_state":[]}
	}, queue_name='health')
	if r == {"result":{"question":"Are you a Sole trader, Partnership, Company or Trust?","state":[{"question_id":0,"response":-1}]}}:
		return "ok"
	else:
		raise HTTPException(status_code=500, detail="self-test failed")


@app.post("/chat")
def post(body: ChatRequest, request: Request):
	return json_prolog_rpc_call(request, {
		"method": "chat",
		"params": body.dict(),
	})


def json_prolog_rpc_call(request, msg, queue_name=None):
	msg["client"] = request.client.host
	return worker.call_remote_rpc_job(msg, queue_name).result.get(block=True, timeout=1000 * 1000)




def tmp_file_url(public_url, tmp_dir_name, fn):
	return public_url + '/tmp/' + tmp_dir_name + '/' + urllib.parse.quote(fn)



@app.get("/view/job/{job_id}", response_class=HTMLResponse)
async def views_limbo(request: Request, job_id: str):
	job = await get_task(job_id)
	if job is not None:
		if job['status'] == 'Success' and 'reports' in job['result']:
			return RedirectResponse(find_report_by_key(job['result']['reports'], 'task_directory'))
		else:
			# it turns out that failures are not permanent
			return templates.TemplateResponse("job.html", {"request": request, "job_id": job_id, "json": json.dumps(job, indent=4, sort_keys=True), "refresh": (job['status'] not in [ 'Success']), 'status': job['status']})



@app.get('/api/job/{id}')
async def get_task(id: str):
	r = requests.get(os.environ['REMOULADE_API'] + '/messages/states/' + id)
	if not r.ok:
		return None
	message = r.json()
	if message['actor_name'] not in ["local_calculator"]:
		return None

	# a dict with either result or error key (i think...)
	result = requests.get(os.environ['REMOULADE_API'] + '/messages/result/' + id, params={'max_size':'99999999'})
	logger.info('result: %s' % result.text)
	message['result'] = result.json()

	if 'result' in message['result']:
		message['result'] = json.loads(message['result']['result'])
	return message


@app.post("/reference")
def reference(fileurl: str = Form(...)):#: Annotated[str, Form()]):
	"""
	This endpoint is for running IC on a file that is already on the internet ("by reference").
	"""
	# todo, we should probably instead implement this as a part of "preprocessing" the uploaded content, that is, there'd be a "reference" type of "uploaded file", and the referenced url should then also be retrieved in a unified way along with retrieving for example xbrl taxonomies referenced by xbrl files.

	# is this a onedrive url? 
	if urllib.parse.urlparse(fileurl).netloc.endswith("db.files.1drv.com"):

		# get the file
		r = requests.get(fileurl)
		
		request_tmp_directory_name, request_tmp_directory_path = create_tmp()
		
		# save r into request_tmp_directory_path
		fn = request_tmp_directory_path + '/file1.xlsx' # hack! we assume everything coming through this endpoint is an excel file
		with open(fn, 'wb') as f:
			f.write(r.content)

		return process_request(request_tmp_directory_name)

	


@app.post("/upload")
def upload(file1: Optional[UploadFile]=None, file2: Optional[UploadFile]=None, request_format:str='rdf', requested_output_format:str='job_handle'):
	
	request_tmp_directory_name, request_tmp_directory_path = create_tmp()

	for file in filter(None, [file1, file2]):
		logger.info('uploaded: %s' % file)
		uploaded = save_uploaded_file(request_tmp_directory_path, file)

	return process_request(request_tmp_directory_name, requested_output_format)




def process_request(request_directory, requested_output_format = 'job_handle'):
	public_url=os.environ['PUBLIC_URL']

	job = worker.trigger_remote_calculator_job(
		request_directory=request_directory,
		public_url=public_url,
	)

	logger.info('requested_output_format: %s' % requested_output_format)

	if requested_output_format == 'immediate_xml':
			reports = job.result.get(block=True, timeout=1000 * 1000)
			return RedirectResponse(find_report_by_key(reports['reports'], 'response'))
	elif requested_output_format == 'immediate_json_reports_list':
			reports = job.result.get(block=True, timeout=1000 * 1000)
			return RedirectResponse(find_report_by_key(reports['reports'], 'task_directory') + '/000000_response.json.json')
	elif requested_output_format == 'job_handle':
		return JSONResponse(
		{
			"alerts": ["job scheduled."],
			"reports":
			[{
				"title": "job URL",
				"key": "job_tmp_url",
				"val":{"url": tmp_file_url(public_url, job.message_id, '')}},
			{
				"title": "job API URL",
				"key": "job_api_url",
				"val":{"url": public_url + '/api/job/' + job.message_id}},
			{
				"title": "job view URL",
				"key": "job_view_url",
				"val":{"url": public_url + '/view/job/' + job.message_id}},
			]
		})
	else:
		raise Exception('unexpected requested_output_format')


def save_uploaded_file(tmp_directory_path, src):
	logger.info('src: %s' % src)
	dest = os.path.abspath('/'.join([tmp_directory_path, ntpath.basename(src.filename)]))
	with open(dest, 'wb+') as dest_fd:
		shutil.copyfileobj(src.file, dest_fd)
	return dest





	


# also: def fill_workbook_with_template():
	# either generate a xlsx file and return it to client, to be saved to onedrive (or to overwrite the selected onedrive xlsx file)
	# or run a direct request to msft graph api here


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
	return PlainTextResponse(str(exc), status_code=400)



"""
FastAPI def vs async def:

When you declare a path operation function with normal def instead of async def, it is run in an external threadpool that is then awaited, instead of being called directly (as it would block the server).

If you are coming from another async framework that does not work in the way described above and you are used to define trivial compute-only path operation functions with plain def for a tiny performance gain (about 100 nanoseconds), please note that in FastAPI the effect would be quite opposite. In these cases, it's better to use async def unless your path operation functions use code that performs blocking I/O.
- https://fastapi.tiangolo.com/async/
"""

# https://12factor.net/

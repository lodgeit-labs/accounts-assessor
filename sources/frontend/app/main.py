import os, sys
import urllib.parse
import json
import datetime
import ntpath
import shutil
import requests

from typing import Optional, Any, List
from fastapi import FastAPI, Request, File, UploadFile, HTTPException
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



from agraph import agc
import invoke_rpc
from tasking import remoulade
from fs_utils import directory_files, find_report_by_key
from tmp_dir_path import create_tmp
import call_prolog_calculator
import logging





class ChatRequest(BaseModel):
	type: str
	current_state: list[Any]

class RpcCommand(BaseModel):
	method: str
	params: Any




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
#...

@app.post("/health_check")
def post(request: Request):
	r = json_prolog_rpc_call(request, {
		"method": "chat",
		"params": {"type":"sbe","current_state":[]}
	})
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


def json_prolog_rpc_call(request, msg):
	msg["client"] = request.client.host
	return invoke_rpc.call_prolog.send(msg=msg).result.get(block=True, timeout=1000 * 1000)




def tmp_file_url(server_url, tmp_dir_name, fn):
	return server_url + '/tmp/' + tmp_dir_name + '/' + urllib.parse.quote(fn)



@app.get("/view/job/{job_id}", response_class=HTMLResponse)
async def views_limbo(request: Request, job_id: str):
	job = await get_task(job_id)
	if job is not None:
		if job['status'] == 'Success' and 'reports' in job['result'].get('result',{}):
			return RedirectResponse(find_report_by_key(job['result']['result']['reports'], 'task_directory'))
		else:
			# it turns out that failures are not permanent
			return templates.TemplateResponse("job.html", {"request": request, "job_id": job_id, "json": json.dumps(job, indent=4, sort_keys=True), "refresh": (job['status'] not in [ 'Success']), 'status': job['status']})



@app.get('/api/job/{id}')
async def get_task(id: str):
	r = requests.get(os.environ['REMOULADE_API'] + '/messages/states/' + id)
	if not r.ok:
		return None
	message = r.json()
	if message['actor_name'] not in ["call_prolog_calculator2"]:
		return None
	message['result'] = requests.get(os.environ['REMOULADE_API'] + '/messages/result/' + id).json()
	if 'result' in message['result']:
		message['result']['result'] = json.loads(message['result']['result'])
	return message


@app.post("/upload")
def post(file1: Optional[UploadFile]=None, file2: Optional[UploadFile]=None, request_format:str='rdf', requested_output_format:str='job_handle'):
	"""
	'json_reports_list' is a misnomer at this point, these requests process asynchronously, and we only return what is basically a result handle (url).
	otherwise, we block waiting for prolog to finish, or for client to give up.
	"""
	server_url=os.environ['PUBLIC_URL']

	request_tmp_directory_name, request_tmp_directory_path = create_tmp()
	#final_result_tmp_directory_name, final_result_tmp_directory_path = create_tmp()

	logging.getLogger().warn('file1: %s, file2: %s' % (file1, file2))
	request_files_in_tmp = save_request_files(file1, file2, request_tmp_directory_path)

	job = call_prolog_calculator.call_prolog_calculator(
		request_tmp_directory_name=request_tmp_directory_name,
		server_url=server_url,
		request_files=request_files_in_tmp,
		request_format = request_format,
		final_result_tmp_directory_name = None,#final_result_tmp_directory_name,
		final_result_tmp_directory_path = None,#final_result_tmp_directory_path,
	)

	logging.getLogger().info('job.message_id: %s' % job.message_id)
	final_result_tmp_directory_name = job.message_id

	# the limit here is that the excel plugin doesn't do any async or such. It will block until either a response is received, or it timeouts.
	# for json_reports_list, we must choose a timeout that happens faster than client's timeout. If client timeouts, it will have received nothing and can't even open browser or let user load result sheets manually
	# but if we timeout too soon, we will have no chance to send a full reports list with result sheets, and users will get an unnecessary browser window + will have to load sheets manually.
	# with xml requests, there is no way to indicate any errors, so just try to process it in time, and let the client timeout if it takes too long.
	logging.getLogger().info('requested_output_format: %s' % requested_output_format)
	if requested_output_format in ['immediate_xml', 'immediate_json_reports_list']:
		reports = job.result.get(block=True, timeout=1000 * 1000)
		if requested_output_format == 'immediate_xml':
			return RedirectResponse(find_report_by_key(reports['reports'], 'response'))
		else:
			return RedirectResponse(find_report_by_key(reports['reports'], 'task_directory') + '/000000_response.json.json')
	elif requested_output_format == 'job_handle':
		return JSONResponse(
		{
			"alerts": ["job scheduled."],
			"reports":
			[{
				"title": "job URL",
				"key": "job_tmp_url",
				"val":{"url": tmp_file_url(server_url, final_result_tmp_directory_name, '')}},
			{
				"title": "job API URL",
				"key": "job_api_url",
				"val":{"url": server_url + '/api/job/' + final_result_tmp_directory_name}},
			{
				"title": "job view URL",
				"key": "job_view_url",
				"val":{"url": server_url + '/view/job/' + final_result_tmp_directory_name}},
			]
		})
	else:
		raise Exception('unexpected requested_output_format')


def save_request_files(file1, file2, request_tmp_directory_path):
	request_files_in_tmp=[]
	for file in filter(None, [file1, file2]):
		logging.getLogger().info('file: %s' % file)
		request_files_in_tmp.append(save_uploaded_file(request_tmp_directory_path, file))
	return request_files_in_tmp


def save_uploaded_file(tmp_directory_path, src):
	logging.getLogger().warn('src: %s' % src)
	dest = os.path.abspath('/'.join([tmp_directory_path, ntpath.basename(src.filename)]))
	with open(dest, 'wb+') as dest_fd:
		shutil.copyfileobj(src.file, dest_fd)
	return dest


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

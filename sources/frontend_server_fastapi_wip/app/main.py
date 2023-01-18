import os, sys
import urllib.parse
import json
import datetime
import ntpath
import shutil


from typing import Optional, Any, List
from fastapi import FastAPI, Request, File, UploadFile, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.responses import PlainTextResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel



sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../internal_workers')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common')))
##sys.path.append(os.path.normpath('/app/sources/common/'))



from agraph import agc
import invoke_rpc
import selftest
from tasking import remoulade
from fs_utils import directory_files
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





def ee(context_manager):
	return ExitStack().enter_context(context_manager)

def secret(key):
	try:
		stack = ee(open('/run/secrets/'+key))
	except FileNotFoundError:
		pass
	else:
		with stack as f:
			return f.read().rstrip('\n')


	return os.environ[key]



app = FastAPI()


@app.get("/")
async def read_root():
	return {"Hello": "World"}


@app.post("/chat")
async def post(body: ChatRequest, request: Request):
	return json_prolog_rpc_call(request, {
		"method": "chat",
		"params": body.dict(),
	})


def json_prolog_rpc_call(request, msg):
	msg["client"] = request.client.host
	return invoke_rpc.call_prolog.send(msg=msg).result.get(block=True, timeout=1000 * 1000)


@app.post("/rpc")
async def rpc(cmd: RpcCommand, request: Request):
	if cmd.method == 'start_selftest_session':
		task = selftest.start_selftest_session(cmd.params['target_server_url'])
		return {'@id':str(task)}
	if cmd.method == 'selftest_session_query_string1':
		session = last_session()
		if session is not None:
			return selftest.testcases_query1 % session
		else:
			return None


@app.post("/rpc/start_selftest_session")
async def rpc(args: dict):
	return {'@id':str(selftest.start_selftest_session(args['target_server_url']))}



def find_report_by_key(reports, name):
	for i in reports:
		if i['key'] == name:
			return i['val']['url']



def tmp_file_url(server_url, tmp_dir_name, fn):
	return server_url + '/tmp/' + tmp_dir_name + '/' + urllib.parse.quote(fn)


def save_uploaded_file(tmp_directory_path, src):
	dest = os.path.abspath('/'.join([tmp_directory_path, ntpath.basename(src.filename)]))
	with open(dest, 'wb+') as dest_fd:
		shutil.copyfileobj(src.file, dest_fd)
	return dest



@app.post("/upload")
async def post(file1: Optional[UploadFile]=None, file2: Optional[UploadFile]=None, request_format:str=None, requested_output_format:str='json_reports_list'):
	"""
	'json_reports_list' is a misnomer at this point, these requests process asynchronously, and we only return what is basically a result handle (url).
	otherwise, we block waiting for prolog to finish, or for client to give up.
	"""
	request_tmp_directory_name, request_tmp_directory_path = create_tmp()
	request_files_in_tmp = await save_request_files(file1, file2, request_tmp_directory_path)

	final_result_tmp_directory_name, final_result_tmp_directory_path = create_tmp()
	result = call_prolog_calculator.call_prolog_calculator(
		request_tmp_directory_name=request_tmp_directory_name,
		server_url=os.environ['PUBLIC_URL'],
		request_files=request_files_in_tmp,
		# the limit here is that the excel plugin doesn't do any async or such. It will block until either a response is received, or it timeouts.
		# for json_reports_list, we must choose a timeout that happens faster than client's timeout. If client timeouts, it will have received nothing and can't even open browser or let user load result sheets manually
		# but if we timeout too soon, we will have no chance to send a full reports list with result sheets, and users will get an unnecessary browser window + will have to load sheets manually.
		# with xml requests, there is no way to indicate any errors, so just try to process it in time, and let the client timeout if it takes too long.
		request_format = request_format,
		final_result_tmp_directory_name = final_result_tmp_directory_name,
		final_result_tmp_directory_path = final_result_tmp_directory_path
	)

	logging.getLogger().info('requested_output_format: %s' % requested_output_format)

	if requested_output_format == 'immediate_xml':
		response_tmp_directory_name = result.get(block=True, timeout=1000 * 1000)
		reports = json.load(open('/app/server_root/tmp/' + response_tmp_directory_name + '/000000_response.json.json'))
		redirect_url = find_report_by_key(reports['reports'], 'response')
	elif requested_output_format == 'task_handle':
		return JsonResponse(
		{
			"alerts": ["result will be ready at the following URL."],
			"reports":
			[{
				"title": "task_handle",
				"key": "task_handle",
				"val":{"url": tmp_file_url(server_url, final_result_tmp_directory_name, '')}}
			]
		})
	# else:
	# 	redirect_url = '/tmp/'+ response_tmp_directory_name + '/000000_response.json.json'
	# 	logging.getLogger().warn('redirect url: %s' % redirect_url)
	# 	return RedirectResponse(redirect_url)
	else:
		raise Exception('unexpected requested_output_format')


async def save_request_files(file1, file2, request_tmp_directory_path):
	request_files_in_tmp = list(filter(None, [file1, file2]))
	for file in request_files_in_tmp:
		request_files_in_tmp.append(save_uploaded_file(request_tmp_directory_path, file))
	return request_files_in_tmp


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

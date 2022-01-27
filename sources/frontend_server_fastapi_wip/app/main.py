import os, sys
import urllib.parse
import json
import datetime
import ntpath
import shutil


from typing import Optional, Any
from fastapi import FastAPI, Request, File, UploadFile
from pydantic import BaseModel



sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../internal_workers')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common')))
##sys.path.append(os.path.normpath('/app/sources/common/'))
import robust_nodocker



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


@app.post("/clients/chat")
async def post(body: ChatRequest, request: Request):
	return json_prolog_rpc_call(request, {
		"method": "chat",
		"params": body.dict(),
	})


def json_prolog_rpc_call(request, msg):
	msg["client"] = request.client.host
	return invoke_rpc.call_prolog.send(msg=msg).result.get(block=True, timeout=1000 * 1000)


@app.post("/backend/rpc")
async def rpc(cmd: RpcCommand, request: Request):
	if cmd.method == 'selftest':
		task = selftest.start_selftest_session(cmd.params['target_server_url'])
		return {'@id':str(task)}




def find_report_by_key(reports, name):
	for i in reports:
		if i['key'] == name:
			return i['val']['url']



def tmp_file_url(server_url, tmp_dir_name, fn):
	return server_url + '/tmp/' + tmp_dir_name + '/' + urllib.parse.quote(fn)


def save_uploaded_file(dir, src):
	dest = os.path.abspath('/'.join([tmp_directory_path, ntpath.basename(f.filename)]))
	with open(dest, 'wb+') as dest_fd:
		shutil.copyfileobj(src, dest_fd)
	return dest





@app.post("/clients/upload")
async def post(files: list[UploadFile], request: Request, request_format: str, requested_output_format='json_reports_list'):
	request_tmp_directory_name, request_tmp_directory_path = create_tmp()
	request_files_in_tmp = []
	for file in files:
		request_files_in_tmp.append(save_uploaded_file(request_tmp_directory_path, file))
	final_result_tmp_directory_name, final_result_tmp_directory_path = create_tmp()
	response_tmp_directory_name = None
	response_tmp_directory_name = call_prolog_calculator.call_prolog_calculator(
		celery_app = celery_app,
		prolog_flags=prolog_flags,
		request_tmp_directory_name=request_tmp_directory_name,
		server_url=server_url,
		request_files=request_files_in_tmp,
		# the limit here is that the excel plugin doesn't do any async or such. It will block until either a response is received, or it timeouts.
		# for json_reports_list, we must choose a timeout that happens faster than client's timeout. If client timeouts, it will have received nothing and can't even open browser or let user load result sheets manually
		# but if we timeout too soon, we will have no chance to send a full reports list with result sheets, and users will get an unnecessary browser window + will have to load sheets manually.
		# for xml there is no way to indicate any errors, so just let client do the timeouting.
		timeout_seconds = 30 if requested_output_format == 'json_reports_list' else 0,
		request_format = request_format,
		final_result_tmp_directory_name = final_result_tmp_directory_name,
		final_result_tmp_directory_path = final_result_tmp_directory_path
	)

	logging.getLogger().warn('requested_output_format: %s' % requested_output_format)
	if requested_output_format == 'xml':
		reports = json.load(open('/app/server_root/tmp/' + response_tmp_directory_name + '/000000_response.json.json'))
		redirect_url = find_report_by_key(reports['reports'], 'response')
	else:
		if response_tmp_directory_name == None: # timeout happened
			return JsonResponse(
			{
				"alerts": ["timeout."],
				"reports":
				[{
					"title": "task_handle",
					"key": "task_handle",
					"val":{"url": tmp_file_url(server_url, final_result_tmp_directory_name, '')}}
				]
			})
		else:
			if requested_output_format == 'json_reports_list':
				redirect_url = '/tmp/'+ response_tmp_directory_name + '/000000_response.json.json'
			else:
				raise Exception('unexpected requested_output_format')
	logging.getLogger().warn('redirect url: %s' % redirect_url)
	return HttpResponseRedirect(redirect_url)











"""
FastAPI def vs async def:

When you declare a path operation function with normal def instead of async def, it is run in an external threadpool that is then awaited, instead of being called directly (as it would block the server).

If you are coming from another async framework that does not work in the way described above and you are used to define trivial compute-only path operation functions with plain def for a tiny performance gain (about 100 nanoseconds), please note that in FastAPI the effect would be quite opposite. In these cases, it's better to use async def unless your path operation functions use code that performs blocking I/O.
- https://fastapi.tiangolo.com/async/
"""

# https://12factor.net/

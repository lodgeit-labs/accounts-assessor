import os, sys
import urllib.parse
import json
import datetime



from typing import Optional, Any
from fastapi import FastAPI, Request
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



def tmp_file_url(server_url, tmp_dir_name, fn):
	return server_url + '/tmp/' + tmp_dir_name + '/' + urllib.parse.quote(fn)


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



"""
FastAPI def vs async def:

When you declare a path operation function with normal def instead of async def, it is run in an external threadpool that is then awaited, instead of being called directly (as it would block the server).

If you are coming from another async framework that does not work in the way described above and you are used to define trivial compute-only path operation functions with plain def for a tiny performance gain (about 100 nanoseconds), please note that in FastAPI the effect would be quite opposite. In these cases, it's better to use async def unless your path operation functions use code that performs blocking I/O.
- https://fastapi.tiangolo.com/async/
"""

# https://12factor.net/

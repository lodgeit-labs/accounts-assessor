#!/usr/bin/env python3

import os, sys
import threading

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/python')))
from tasking import remoulade






from json import JSONDecodeError
from fastapi.encoders import jsonable_encoder
import dateutil.parser
import logging
import os, sys
import urllib.parse
import json
import datetime
from datetime import date
import ntpath
import shutil
import re
from pathlib import Path as P
from typing import Optional, Any, List, Annotated
from fastapi import FastAPI, Request, File, UploadFile, HTTPException, Form, status, Query, Header
from fastapi.exceptions import RequestValidationError
from fastapi.responses import PlainTextResponse, JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.responses import RedirectResponse, PlainTextResponse, HTMLResponse
from pydantic import BaseModel
from fastapi.templating import Jinja2Templates






# ┏━┓┏━┓╻ ╻   ┏━┓┏━┓┏━╸
# ┣┳┛┣━┫┃╻┃   ┣┳┛┣━┛┃
# ╹┗╸╹ ╹┗┻┛   ╹┗╸╹  ┗━╸


def call_remote_rpc_job(msg, queue='default'):
	return local_rpc.send_with_options(kwargs={'msg':msg}, queue_name=queue)

@remoulade.actor(alternative_queues=["health"])
def local_rpc(msg, options=None):
	return invoke_rpc.call_prolog(msg, options)




# ┏━╸┏━┓╻  ┏━╸╻ ╻╻  ┏━┓╺┳╸┏━┓┏━┓
# ┃  ┣━┫┃  ┃  ┃ ┃┃  ┣━┫ ┃ ┃ ┃┣┳┛
# ┗━╸╹ ╹┗━╸┗━╸┗━┛┗━╸╹ ╹ ╹ ┗━┛╹┗╸

def trigger_remote_calculator_job(**kwargs):
	return local_calculator.send_with_options(kwargs=kwargs)

@remoulade.actor(time_limit=1000*60*60*24*365*1000)
def local_calculator(
	request_directory: str,
	public_url='http://localhost:8877',
	worker_options=None,
	request_format=None
):
	msg = dict(
		method='calculator',
		params=dict(
			request_format=request_format,
			request_tmp_directory_name = request_directory,
			request_files = convert_request_files(files_in_dir(get_tmp_directory_absolute_path(request_directory))),
			public_url = public_url
		)
	)
	update_last_request_symlink(request_directory)
	return invoke_rpc.call_prolog_calculator(msg=msg, worker_options=worker_options)




#print(local_calculator.fn)
remoulade.declare_actors([local_rpc, local_calculator])






app = FastAPI(
	title="Robust API",
	summary="invoke accounting calculators and other endpoints",
	#servers = [dict(url=os.environ['PUBLIC_URL'][:-1])],
)


from app.dotdict import Dotdict

from remoulade.__main__ import start_worker

def start_worker2():
	remoulade_worker_args = Dotdict(dict(
		modules=[],
		queues=['default'],
		threads=1,
		prefetch_multiplier=1))
	print(start_worker(remoulade_worker_args, logging.getLogger('remoulade')))


print(threading.Thread(target=start_worker2, daemon=True).start())


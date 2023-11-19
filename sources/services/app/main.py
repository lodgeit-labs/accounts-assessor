import os, sys, logging, re
import urllib.parse
import json
import datetime
import ntpath
import shutil, shlex, subprocess
from typing import Optional, Any
from fastapi import FastAPI, Request, File, UploadFile
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import requests, glob
from pathlib import Path as P
import xmlschema
import traceback


log = logging.getLogger(__name__)

app = FastAPI()

schemas = {}


from . import account_hierarchy
from . import div7a


@app.post("/div7a")
def post_div7a(loan_summary_request: dict):
	log.info(json.dumps(loan_summary_request))
	try:
		result = dict(result=div7a.div7a_from_json(loan_summary_request['data'], loan_summary_request['tmp_dir_path']))
	except div7a.MyException as e:
		result = dict(result='error', error_message=str(e))
	except Exception as e:
		traceback_message = traceback.format_exc()
		result = dict(result='error', error_message=traceback_message)
	log.info(result)
	return result

@app.post("/arelle_extract")
def post_arelle_extract(taxonomy_locator: str):
	return account_hierarchy.ArelleController().run(taxonomy_locator)


@app.get("/")
def index():
	return "ok"



from pydantic import BaseModel


class ShellRequest(BaseModel):
    cmd: list[str]

@app.post("/shell")
def shell(shell_request: ShellRequest):
	cmd = [shlex.quote(x) for x in shell_request.cmd]
	print(cmd)
	#p = subprocess.Popen(cmd, universal_newlines=True)  # text=True)
	p=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True)#text=True)
	(stdout,stderr) = p.communicate()
	if p.returncode == 0:
		status = 'ok'
	else:
		status = 'error'
	return JSONResponse({'status':status,'stdout':stdout,'stderr':stderr})



def parse_schema(xsd):
	return xmlschema.XMLSchema(xsd)

def get_schema(xsd):
	if xsd in schemas:
		schema = schemas[xsd]
	else:
		schema = parse_schema(xsd)
		schemas[xsd] = schema
	return schema

@app.post('/xml_xsd_validator')
def xml_xsd_validator(xml: str, xsd:str):
	""" fixme: limit these to some directories / hosts... """
	schema = get_schema(xsd)
	response = {}
	try:
		schema.validate(xml)
		response['result'] = 'ok'
	except Exception as e:
		response['error_message'] = str(e)
		response['error_type'] = str(type(e))
		response['result'] = 'error'
	return JSONResponse(response)


@app.post('/fetch_remote_file')
def fetch_remote_file(tmp_dir_path: str, url: str):
	log.debug(url)

	url = correct_onedrive_url(url)

	path = P(tmp_dir_path) / 'remote_files'
	path.mkdir(exist_ok=True)


	existing_items = list(path.glob('*'))
	log.debug(existing_items)


	existing_items_count = len(existing_items)
	path = path / str(existing_items_count)
	log.debug(path)

	path.mkdir(exist_ok=True)
	log.debug(url)
	proc = subprocess.run(['wget', url], cwd=path, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
	files = list(path.glob('*'))

	if len(files) == 1:
		r = dict(result='ok', file_path=str(path / files[0]))
	else:
		r = dict(result='error', error_message=proc.stdout)

	log.info(r)
	return JSONResponse(r)

def correct_onedrive_url(url):
	try:
		return 'https://api.onedrive.com/v1.0/shares/s!'+re.search(r'https://1drv.ms/u/s\!(.*?)\?.*', url).group(1)+'/root/content'
	except:
		return url

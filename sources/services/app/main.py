import os, sys, logging, re
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/misc')))
import div7a2
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




@app.post("/div7a2")
def post_div7a2(
	request: dict
):
	log.info(json.dumps(request))
	try:
		result = dict(result=div7a.div7a2_from_json(request['request'], request['tmp_dir_path']))
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
	"""
	:param source: an URI that reference to a resource or a file path or a file-like \
	    object or a string containing the schema or an Element or an ElementTree document \
	    or an :class:`XMLResource` instance. A multi source initialization is supported \
	    providing a not empty list of XSD sources.
	
	:param allow: defines the security mode for accessing resource locations. Can be \
	    'all', 'remote', 'local' or 'sandbox'. Default is 'all' that means all types of \
	    URLs are allowed. With 'remote' only remote resource URLs are allowed. With 'local' \
	    only file paths and URLs are allowed. With 'sandbox' only file paths and URLs that \
	    are under the directory path identified by source or by the *base_url* argument \
	    are allowed.
	"""

	# this is overly strict, we will need to allow our schemes directory, at least

	return xmlschema.XMLSchema(xsd, allow='none', defuse='always')

def get_schema(xsd):
	if xsd in schemas:
		schema = schemas[xsd]
	else:
		schema = parse_schema(xsd)
		schemas[xsd] = schema
	return schema

@app.post('/xml_xsd_validator')
def xml_xsd_validator(xml: str, xsd:str):
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


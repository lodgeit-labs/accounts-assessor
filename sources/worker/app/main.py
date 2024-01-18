from fastapi import FastAPI
from fastapi.responses import JSONResponse
import logging
import os, sys, logging, re
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/misc')))


# this will run in background thread
from app import worker



# these are helper api
from app import account_hierarchy
from app import xml_xsd


log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.addHandler(logging.StreamHandler(sys.stderr))



app = FastAPI(
	title="Robust worker private api"
)


# helper functions that prolog can call


@app.get("/")
def root():
	return "ok"


@app.post("/arelle_extract")
def post_arelle_extract(taxonomy_locator: str):
	return account_hierarchy.ArelleController().run(taxonomy_locator)


@app.post('/xml_xsd_validator')
def xml_xsd_validator(xml: str, xsd: str):
	schema = xml_xsd.get_schema(xsd)
	response = {}
	try:
		schema.validate(xml)
		response['result'] = 'ok'
	except Exception as e:
		response['error_message'] = str(e)
		response['error_type'] = str(type(e))
		response['result'] = 'error'
	return JSONResponse(response)

from fastapi import FastAPI
from fastapi.responses import JSONResponse



# this will run in background thread
from worker import *

# these are helper api
from app import account_hierarchy
from app import xml




log = logging.getLogger(__name__)

app = FastAPI(
	title="Robust worker private api"
)


# helper functions that prolog can call


@app.post("/arelle_extract")
def post_arelle_extract(taxonomy_locator: str):
	return account_hierarchy.ArelleController().run(taxonomy_locator)


@app.post('/xml_xsd_validator')
def xml_xsd_validator(xml: str, xsd: str):
	schema = xml.get_schema(xsd)
	response = {}
	try:
		schema.validate(xml)
		response['result'] = 'ok'
	except Exception as e:
		response['error_message'] = str(e)
		response['error_type'] = str(type(e))
		response['result'] = 'error'
	return JSONResponse(response)

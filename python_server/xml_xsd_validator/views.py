"""
curl "http://localhost:8123/xml_xsd_validator/?xml=/home/sfi/t-rex/lodgeit2/lodgeit/prolog_server/tmp/1567006362.8642542.15/loan-request4.xml&xsd=/home/sfi/t-rex/lodgeit2/lodgeit/prolog_server/schemas/bases/Reports.xsd"
{"result": "ok"}
"""

from django.http import JsonResponse
import xmlschema

schemas = {}
# = xmlschema.XMLSchema('/home/sfi/t-rex/lodgeit2/lodgeit/prolog_server/schemas/bases/Reports.xsd')



def parse_schema(xsd):
	return xmlschema.XMLSchema(xsd)

def get_schema(xsd):
	if xsd in schemas:
		schema = schemas[xsd]
	else:
		schema = parse_schema(xsd)
		schemas[xsd] = schema
	return schema


def index(request):
	#print(request.GET)
	params = request.GET

	""" fixme: limit these to some directories / hosts """
	xml = params['xml']
	xsd = params['xsd']
	
	schema = get_schema(xsd)
	
	response = {}
	try:
		schema.validate(xml)
		response['result'] = 'ok'
	except Exception as e:
		response['error_message'] = str(e)
		response['error_type'] = str(type(e))
		response['result'] = 'error'
	return JsonResponse(response)



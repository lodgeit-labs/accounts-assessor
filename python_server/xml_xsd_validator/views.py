"""
curl "http://localhost:8123/xml_xsd_validator/?xml=/home/sfi/t-rex/lodgeit2/lodgeit/prolog_server/tmp/1567006362.8642542.15/loan-request4.xml&xsd=/home/sfi/t-rex/lodgeit2/lodgeit/prolog_server/schemas/bases/Reports.xsd"
{"result": "ok"}
"""

from django.http import JsonResponse
import xmlschema

schemas = {}
# = xmlschema.XMLSchema('/home/sfi/t-rex/lodgeit2/lodgeit/prolog_server/schemas/bases/Reports.xsd')


def index(request):
	#print(request.GET)
	params = request.GET

	""" fixme: limit these to some directories / hosts """
	xml = params['xml']
	xsd = params['xsd']

	if xsd in schemas:
		schema = schemas[xsd]
	else:
		schema = xmlschema.XMLSchema(xsd)
		schemas[xsd] = schema
	response = {}
	try:
		schema.validate(xml)
		response['result'] = 'ok'
	except Exception as e:
		response['error_message'] = str(e)
		response['error_type'] = str(type(e))
		response['result'] = 'error'
	return JsonResponse(response)



from modernrpc.core import rpc_method

from json import JSONDecoder
from django.core.serializers.json import DjangoJSONEncoder

import fractions
import os
from franz.openrdf.connect import ag_connect

"""

curl -X POST  -d '{"jsonrpc":"2.0","id":"curltext","method":"agraph_sparql","params":{"sparql":"clear graphs"}}' -H 'content-type:application/json;' http://localhost:17778/rpc/

"""


@rpc_method
def agraph_sparql(sparql):
	c = ag_connect('a', host='localhost', port='10035', user=os.environ['AGRAPH_USER'],
				   password=os.environ['AGRAPH_PASS'])



	return str(c)


@rpc_method
def add(a, b):
	return a + b

@rpc_method
def gb_number_to_rational(s):
	return fractions.Fraction(filter_out_apostrophes(s))

@rpc_method
def filter_out_apostrophes(s):
	s2 = ''
	for i in s:
		if i != "'":
			s2 = s2 + i
	return s2

class MyJSONDecoder(JSONDecoder):
	@staticmethod
	def hook(dct):
		if '__complex__' in dct:
			return complex(dct['real'], dct['imag'])
		return dct

	def __init__(s):
		super().__init__(object_hook=MyJSONDecoder.hook)

class MyDjangoJSONEncoder(DjangoJSONEncoder):
	pass



#def ok(value):
#	value2 = json.dumps(value)
#	return JsonResponse({'status': 'ok', 'result': value2})

from modernrpc.core import rpc_method
import fractions
from django.core.serializers.json import DjangoJSONEncoder
#from django.core.serializers.json import Des

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
		super().__init__(object_hook=hook)

class MyDjangoJSONEncoder(DjangoJSONEncoder):
	pass










#def ok(value):
#	value2 = json.dumps(value)
#	return JsonResponse({'status': 'ok', 'result': value2})


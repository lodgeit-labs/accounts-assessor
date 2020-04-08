from modernrpc.core import rpc_method

from json import JSONDecoder
from django.core.serializers.json import DjangoJSONEncoder

import fractions
import os
from franz.openrdf.connect import ag_connect

from lib import account_hierarchy

@rpc_method
def arelle_extract(taxonomy_locator):
	return account_hierarchy.ArelleController().run(taxonomy_locator)



"""

curl -X POST  -d '{"jsonrpc":"2.0","id":"curltext","method":"agraph_sparql","params":{"sparql":"clear graphs"}}' -H 'content-type:application/json;' http://localhost:17778/rpc/

"""
"""
koom@koom-KVM ~/agr/lib> ./agraph-control --config ./agraph.cfg start

AllegroGraph Server Edition 6.6.0, built on August 02, 2019 12:40:40 GMT-0700
Copyright (c) 2005-2019 Franz Inc.  All Rights Reserved.
AllegroGraph contains patented and patent-pending technologies.

current-time    : Tuesday, February 18, 2020 12:06:55 PM 

Daemonizing...
Server started normally: Running with free license of 5,000,000 triples; no-expiration.
Access AGWebView at http://127.0.0.1:10035
"""


def agc():
	return ag_connect('a', host='localhost', port='10035', user=os.environ['AGRAPH_USER'],
				   password=os.environ['AGRAPH_PASS'])


@rpc_method
def agraph_sparql(sparql):
	#agc().
	return str(c)

@rpc_method

def agraph_addFile(sparql):
	#https://franz.com/agraph/support/documentation/current/python/_gen/franz.openrdf.repository.html#franz.openrdf.repository.repositoryconnection.RepositoryConnection.addFile
# addFile(filePath, base=None, format=None, context=None, serverSide=False, content_encoding=None, attributes=None, json_ld_store_source=None, json_ld_context=None, allow_external_references=None, external_reference_timeout=None)
	agc().addFile()

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

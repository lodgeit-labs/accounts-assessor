import json, os, logging

from franz.openrdf.model.value import URI
from franz.openrdf.repository.repositoryconnection import RepositoryConnection
from franz.openrdf.connect import ag_connect

from config import secret


registered_prefixes = {}


def generateUniqueUri(prefix):
	"""todo: to ensure uniqueness in the event of agraph server crash, the server should be wrapped in a script that ensures that any code that uses agraph unique id generator is stopped before agraph is started back up. see "ID uniqueness in the event of a crash". Alternatively, look into wrapping the generator call + the call to asserting the triple into the db, with a transaction? Transactions do not cover this i think.
	"""
	#if prefix not in registered_prefixes:
	#	registered_prefixes[prefix] =
	#registerPrefix(a, prefix)
	r = _agc.allocateEncodedIds(prefix)[0]
	logging.getLogger().info(f'allocateEncodedIds: {r}')
	return URI(r)


def registerEncodedIdPrefix(a, prefix):
	a.registerEncodedIdPrefix(prefix, 'https://rdf.lodgeit.net.au/v1/' + prefix + '[a-p]{15}')


namespaces = {
	'kb': 'https://rdf.lodgeit.net.au/v1/kb#'
	'v1': 'https://rdf.lodgeit.net.au/v1'

}

_agc = None

def agc() -> RepositoryConnection:
	global _agc
	if _agc is not None:
		return _agc

	AGRAPH_SECRET_USER = secret('AGRAPH_SUPER_USER')
	AGRAPH_SECRET_PASSWORD = secret('AGRAPH_SUPER_PASSWORD')


	a = ag_connect('a', user=AGRAPH_SECRET_USER, password=AGRAPH_SECRET_PASSWORD)
	a.setDuplicateSuppressionPolicy('spog')

	for k,v in namespaces.items():
		a.setNamespace(k,v)

	registerEncodedIdPrefix(a, 'session')
	registerEncodedIdPrefix(a, 'testcase')

	_agc = a
	return _agc



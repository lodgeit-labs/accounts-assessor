import json, os, logging
from tasking import remoulade

from franz.openrdf.model.value import BNode
from franz.openrdf.vocabulary.rdf import RDF
from franz.openrdf.model.value import URI
from franz.openrdf.repository.repositoryconnection import RepositoryConnection


#def env_or(json, key):
	#print(key, '=', os.environ.get(key), ' or ', json.get(key))
#	return os.environ.get(key) or json.get(key)

from config import secret


#def bn_from_string(bn_str):
#	return BNode(bn_str[2:])

registered_prefixes = {}


def generateUniqueUri(prefix):
	"""todo: to ensure uniqueness in event of agraph server crash, the server should be wrapped in a script that ensures that any code that uses agraph unique id generator is stopped before agraph is started back up. see "ID uniqueness in the event of a crash". Alternatively, look into wrapping the generator call + the call to asserting the triple into the db, with a transaction.
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
	'selftest': 'https://rdf.lodgeit.net.au/v1/selftest#',
	'kb': 'https://rdf.lodgeit.net.au/v1/kb#'
}

@remoulade.actor
def sql_prefixes_header():
	r = ''
	for k,v in namespaces.items():
		r += ('PREFIX ' + k + ': <' + v + '>\n')
	print(r)
	return r

_agc = None

def agc() -> RepositoryConnection:
	global _agc
	if _agc is not None:
		return _agc

	AGRAPH_SECRET_HOST = secret('AGRAPH_SECRET_HOST')
	AGRAPH_SECRET_PORT = secret('AGRAPH_SECRET_PORT')
	AGRAPH_SECRET_USER = secret('AGRAPH_SUPER_USER')
	AGRAPH_SECRET_PASSWORD = secret('AGRAPH_SUPER_PASSWORD')

	if AGRAPH_SECRET_USER != None and AGRAPH_SECRET_PASSWORD != None:
		from franz.openrdf.connect import ag_connect
		#print(f"""ag_connect('a', host={AGRAPH_SECRET_HOST}, port={AGRAPH_SECRET_PORT}, user={AGRAPH_SECRET_USER},password={AGRAPH_SECRET_PASSWORD})""")
		a = ag_connect('a', host=AGRAPH_SECRET_HOST, port=AGRAPH_SECRET_PORT, user=AGRAPH_SECRET_USER, password=AGRAPH_SECRET_PASSWORD)
		a.setDuplicateSuppressionPolicy('spog')
		for k,v in namespaces.items():
			a.setNamespace(k,v)
		registerEncodedIdPrefix(a, 'session')
		registerEncodedIdPrefix(a, 'testcase')
		_agc = a
		return _agc
	else:
		print('agraph user and pass must be provided')
		exit(1)


remoulade.declare_actors([sql_prefixes_header])

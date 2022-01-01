import json, os

from franz.openrdf.model.value import BNode
from franz.openrdf.vocabulary.rdf import RDF
from franz.openrdf.model.value import URI

#def env_or(json, key):
	#print(key, '=', os.environ.get(key), ' or ', json.get(key))
#	return os.environ.get(key) or json.get(key)

def secret(name):
	fn = os.environ.get('SECRETS_DIR','/run/secrets') + '/' + name
	with open(fn, 'r') as x:
		return x.read()


#def bn_from_string(bn_str):
#	return BNode(bn_str[2:])

registered_prefixes = {}


def generateUniqueUri(a, prefix):
	"""todo: to ensure uniqueness in event of agraph server crash, the server should be wrapped in a script that ensures that any code that uses agraph unique id generator is stopped before agraph is started back up. see "ID uniqueness in the event of a crash". Alternatively, look into wrapping the generator call + the call to asserting the triple into the db, with a transaction.
	"""
	#if prefix not in registered_prefixes:
	#	registered_prefixes[prefix] =
	registerPrefix(a, prefix)
	r = a.allocateEncodedIds(prefix)[0]
	return URI(r)


def registerPrefix(a, prefix):
	a.registerEncodedIdPrefix(prefix, 'https://rdf.lodgeit.net.au/v1/' + prefix + '@@[0-n]{10}')


def agc():
	AGRAPH_SECRET_HOST = secret('AGRAPH_SECRET_HOST')
	AGRAPH_SECRET_PORT = secret('AGRAPH_SECRET_PORT')
	AGRAPH_SECRET_USER = secret('AGRAPH_SUPER_USER')
	AGRAPH_SECRET_PASSWORD = secret('AGRAPH_SUPER_PASSWORD')

	if AGRAPH_SECRET_USER != None and AGRAPH_SECRET_PASSWORD != None:
		from franz.openrdf.connect import ag_connect
		#print(f"""ag_connect('a', host={AGRAPH_SECRET_HOST}, port={AGRAPH_SECRET_PORT}, user={AGRAPH_SECRET_USER},password={AGRAPH_SECRET_PASSWORD})""")
		a = ag_connect('a', host=AGRAPH_SECRET_HOST, port=AGRAPH_SECRET_PORT, user=AGRAPH_SECRET_USER, password=AGRAPH_SECRET_PASSWORD)
		a.setDuplicateSuppressionPolicy('spog')
		a.setNamespace('selftest', 'https://rdf.lodgeit.net.au/v1/selftest#')
		registerPrefix(a, 'session')
		registerPrefix(a, 'testcase')
		return a
	else:
		print('agraph user and pass must be provided')
		exit(1)

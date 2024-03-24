import json, os, logging
import franz
from franz.openrdf.model.value import URI
from franz.openrdf.model.literal import Literal
from franz.openrdf.model.utils import parse_term 
from franz.openrdf.repository.repositoryconnection import RepositoryConnection
from franz.openrdf.connect import ag_connect
from config import secret


# see also doc.pl RdfTemplates.trig agraph.py
namespaces = {
	'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	'rdfs': 'http://www.w3.org/2000/01/rdf-schema#',
	'owl': 'http://www.w3.org/2002/07/owl#',
	'dc': 'http://purl.org/dc/elements/1.1/',

	'kb': 'https://rdf.lodgeit.net.au/v1/kb#',
	'v1': 'https://rdf.lodgeit.net.au/v1/',
	'l' : 'https://rdf.lodgeit.net.au/v1/request#',
	'av': 'https://rdf.lodgeit.net.au/v1/action_verbs#',
	'bs': 'https://rdf.lodgeit.net.au/v1/bank_statement#',
	'uv': 'https://rdf.lodgeit.net.au/v1/unit_values#',
	'excel': 'https://rdf.lodgeit.net.au/v1/excel#',
	'rb': 'https://rdf.lodgeit.net.au/v1/robust#',
	'account_taxonomies': 'https://rdf.lodgeit.net.au/v1/account_taxonomies#',
	'div7a_ui': 'https://rdf.lodgeit.net.au/v1/calcs/div7a/ui#',
	'div7a_repayment': 'https://rdf.lodgeit.net.au/v1/calcs/div7a/repayment#',
	'div7a': 'https://rdf.lodgeit.net.au/v1/calcs/div7a#',
	'depr': 'https://rdf.lodgeit.net.au/v1/calcs/depr#',
	'ic': 'https://rdf.lodgeit.net.au/v1/calcs/ic#',
	'hp': 'https://rdf.lodgeit.net.au/v1/calcs/hp#',
	'depr_ui': 'https://rdf.lodgeit.net.au/v1/calcs/depr/ui#',
	'ic_ui': 'https://rdf.lodgeit.net.au/v1/calcs/ic/ui#',
	'hp_ui': 'https://rdf.lodgeit.net.au/v1/calcs/hp/ui#',
	'cars': 'https://rdf.lodgeit.net.au/v1/cars#',
	'smsf': 'https://rdf.lodgeit.net.au/v1/calcs/smsf#',
	'smsf_ui': 'https://rdf.lodgeit.net.au/v1/calcs/smsf/ui#',
	'smsf_distribution': 'https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution#',
	'smsf_distribution_ui': 'https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution_ui#',
	'reallocation': 'https://rdf.lodgeit.net.au/v1/calcs/ic/reallocation#',
	'acc': 'https://rdf.lodgeit.net.au/v1/calcs/ic/accounts#',
	'phases': 'https://rdf.lodgeit.net.au/v1/phases#',
	'transactions': 'https://rdf.lodgeit.net.au/v1/transactions#',
	's_transactions': 'https://rdf.lodgeit.net.au/v1/s_transactions#',
	'report_entries': 'https://rdf.lodgeit.net.au/v1/report_entries#',
	'rdftab': 'https://rdf.lodgeit.net.au/v1/rdftab#',

	'jj' : 'http://jj.internal:8877/tmp/',


}


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


_agcs = {}

def agc(repo='a') -> RepositoryConnection:
	if repo in _agcs:
		return _agcs[repo]

	AGRAPH_SECRET_USER = secret('AGRAPH_SUPER_USER')
	AGRAPH_SECRET_PASSWORD = secret('AGRAPH_SUPER_PASSWORD')

	a: RepositoryConnection = ag_connect(
		repo=repo,
		user=AGRAPH_SECRET_USER,
		password=AGRAPH_SECRET_PASSWORD,
		host=os.environ['AGRAPH_HOST'],
		port=os.environ['AGRAPH_PORT'],


	)
	a.setDuplicateSuppressionPolicy('spog')
	

	for k,v in namespaces.items():
		a.setNamespace(k,v)

	registerEncodedIdPrefix(a, 'session')
	registerEncodedIdPrefix(a, 'testcase')

	_agc = a
	return _agc



def repo_by_user(user):
	if user == 'nobody':
		repo = 'pub'
	else:
		repo = 'a'
	return repo

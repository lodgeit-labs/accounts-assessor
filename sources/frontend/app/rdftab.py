import logging, os
import urllib

import cachetools

import agraph, rdflib
import urllib3.util
from franz.openrdf.query.query import QueryLanguage
from franz.openrdf.repository.repositoryconnection import RepositoryConnection
from rdflib import URIRef, Literal, BNode



logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

ch = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)



def get(user, node: str):
	"""
	render a page displaying all triples for a given URI.
	add a link to gruff or other rdf visualization tools.
	
	format the triples such that the uri is the subject, and the triple is "reversed" if needed.
	sort by importance (some hardcoded predicates go first)
	
	use rdfs:label where available
	
	where the node is a report_entry, add a link to the report.
	where the value has_crosscheck, render the whole crosscheck including both values.
	
	maybe:
	where the value is a string that refers to an account, add a link to the account URI.
	where the node is a vector, display it meaningfully.	
	"""
	logger.info(f"{node=}")
	
	result = dict(user=user, repo=agraph.repo_by_user(user), props=[])
	conn: RepositoryConnection = agraph.agc(result['repo'])
	result['conn'] = conn
	
	queryString = """
	PREFIX franzOption_defaultDatasetBehavior: <franz:rdf>
	
	SELECT ?s ?p ?o ?g ?c WHERE {
			
			{ {GRAPH ?g {?x ?p ?o . }} UNION {?x ?p ?o . } }
			UNION 
			{ {GRAPH ?g {?s ?p ?x .}} UNION {?s ?p ?x .} }
			
			OPTIONAL { ?p rdftab:category ?c1 . }
			bind(if(bound(?c1), ?c1, rdftab:general) as ?c)

	}  ORDER BY ?c ?g ?p ?s ?o LIMIT 1000
	"""
	tupleQuery: agraph.TupleQuery = result['conn'].prepareTupleQuery(QueryLanguage.SPARQL, queryString)
	
	agraph_node = agraph.parse_term(node)

	tupleQuery.setBinding("x", agraph_node)#agraph.URI(uri))
	
	logger.info(f"{agraph_node=} ,  tupleQuery.evaluate() ...")

	# too many namespaces could be a problem, but it might also be a problem for gruff etc, and so might also be too much data in a single repository.
	# So, there might be some need to manage repositories and active namespaces, and they might best be scoped to a single user by default, "pub" being a special case managed by us.
	result['namespaces'] = result['conn'].getNamespaces()
	
	results: agraph.TupleQueryResult
	with tupleQuery.evaluate() as results:
	
		for bindingSet in results:
			c = bindingSet.getValue("c")
			s = bindingSet.getValue("s")
			p = bindingSet.getValue("p")
			o = bindingSet.getValue("o")
			g = bindingSet.getValue("g")
			
			logger.debug(f"bindingSet = {c} {s} {p} {o} {g}")

			c2 = dict(node=c)
			s2 = dict(node=s)
			p2 = dict(node=p)
			o2 = dict(node=o)
			g2 = dict(node=g)
			if g is None:
				g2['fake'] = '(default)'

			if s is None:
				result['props'].append(dict(category=c2, p=p2, o=o2, g=g2))
			elif o is None:
				p2['reverse'] = True
				result['props'].append(dict(category=c2, p=p2, o=s2, g=g2))
			else:
				raise Exception('unexpected!')
			
			
	# todo: browse also literals?
			
	all_props = set()
				
	for prop in result['props']:
		xnode_str(result, prop['category'])
		xnode_str(result, prop['p'])
		xnode_str(result, prop['o'])
		xnode_str(result, prop['g'])
		all_props.add(prop['p']['n3'])
		
	for prop in result['props']:
		add_uri_labels(result, prop['p'])
		add_uri_labels(result, prop['o'])
		add_uri_labels(result, prop['g'])
				
		
	for prop in result['props']:
		logger.info(f"{prop=}")
		if not prop['category']['uri']:
			prop['category']['uri'] = 'https://rdf.lodgeit.net.au/v1/rdftab#general'
		prop['category']['fake'] = prop['category']['uri'].split('#')[-1]
		
	
	result['term'] = dict(node=agraph_node)
	xnode_str(result, result['term'])
	add_uri_labels(result, result['term'])
	add_href(result['term'])
	
	
	if result['term'].get('short') or result['term'].get('label'):
		result['props'].append(dict(
			g=dict(fake='(rdftab)'),
			category=dict(fake='identificational'),
			p=dict(fake='full URI'), 
			o=dict(fake=agraph_node.getURI())
			))


	for prop in result['props']:
		assign_best_display2(prop['g'])

	g = None
	for i, prop in enumerate(result['props']):
		prop['id'] = i
		prop['p']['id'] = 'p' + str(i)
		prop['o']['id'] = 'o' + str(i)
		prop['g']['id'] = 'g' + str(i)
		
		if prop['g'].get('best') != g:
			g = prop['g'].get('best')
		else:
			if i != 0:
				prop['g']['fake'] = 'same as above'
		
	for prop in result['props']:
		for node in [prop['p'], prop['o'], prop['g']]:
			add_href(node)


	add_tools(result)
	return result

	
def add_href(node):
	if node.get('n3'):
		node['href'] = '/static/rdftab/rdftab.html?node=' + urllib.parse.quote_plus(node['n3'])
	node['wtf'] = False
	node['embedded_node'] = {}

	
def xnode_str(result,xn):

	n = xn.get('node')
	logger.info(f"{type(n)=}")
	
	if n is None:
		return

	xn['n3'] = n.toNTriples()

	if isinstance(n, agraph.franz.openrdf.model.literal.Literal):
		s = n.getLabel()
		if len(s) > 100:
			s = s[:100] + '...'
		xn['literal_str'] = s
		xn['datatype'] = n.getDatatype()
		xn['language'] = n.getLanguage()
		
	if isinstance(n, agraph.franz.openrdf.model.value.URI):
		xn['uri'] = n.getURI()
		add_uri_shortening(result, xn)



def add_uri_shortening(result,xnode):
	uri = xnode['uri']
	
	r = uri
	for k,v in result['namespaces'].items():
		if uri.startswith(v) and uri != v:
			rest = uri[len(v):]
			#if len(rest):
			rr = k + ':' + rest
			if len(rr) < len(r):
				r = rr
	if r != uri:
		xnode['short'] = r
	


def add_uri_labels(result, xn):
	if xn.get('node'):
		labels = list(uri_labels(result['conn'], xn['node']))
	else:
		labels = []	
	
	if len(labels) > 0:
		xn['label'] = labels[0]
		xn['other_labels'] = labels[1:]
	else:
		xn['label']=False


@cachetools.cached({})		
def uri_labels(conn, node):

	labels = []
	
	queryString = """
	PREFIX franzOption_defaultDatasetBehavior: <franz:rdf>
	
	SELECT ?l ?g 
	{
  			{GRAPH ?g {?s rdfs:label ?l . }} UNION {?s rdfs:label ?l . }
	} LIMIT 10000
	"""
	tupleQuery: agraph.TupleQuery = conn.prepareTupleQuery(QueryLanguage.SPARQL, queryString)
	tupleQuery.setBinding("s", node)
	results: agraph.TupleQueryResult
	with tupleQuery.evaluate() as results:
		for bindingSet in results:
			labels.append(dict(l=bindingSet.getValue("l").getLabel(), g=bindingSet.getValue("g")))
	return labels
	
	
	

def add_uri_comments(result, xn):
	labels = []
	
	queryString = """
	PREFIX franzOption_defaultDatasetBehavior: <franz:rdf>
	
	SELECT ?l ?g 
	{
  			{
              GRAPH ?g { 
				?s rdfs:comment ?l .
              }
              UNION  
              { 
				?s rdfs:comment ?l .
              }
			}
	} LIMIT 10000
	"""
	tupleQuery: agraph.TupleQuery = result['conn'].prepareTupleQuery(QueryLanguage.SPARQL, queryString)
	tupleQuery.setBinding("s", xn['node'])
	results: agraph.TupleQueryResult
	with tupleQuery.evaluate() as results:	
		for bindingSet in results:
			labels.append(dict(str=bindingSet.getValue("l"), g=bindingSet.getValue("g")))

	if len(labels) > 0:
		xn['comment'] = labels[0]
		xn['other_comments'] = labels[1:]
	else:
		xn['comment']=False
		

		
def assign_best_display2(n):
	if n.get('fake'):
		n['best'] = n['fake']
	elif n.get('label'):
		n['best'] = n['label']['l']
	elif n.get('short'):
		n['best'] = n['short']
	elif n.get('uri'):
		n['best'] = n['uri']
	elif n.get('literal_str'):
		n['best'] = n['literal_str']
	else:
		raise Exception('unexpected!: ' + str(n))
		


def add_tools(result):
	
	repo = result['repo']
	endpoint = os.environ['AGRAPH_URL'] + '/repositories/' + repo + '/statements'
	sp = 'http://www.irisa.fr/LIS/ferre/sparklis/osparklis.html?'
	#uri = result['term']['uri']
	n3 = result['term']['n3']
	
	result['tools'] = [
		dict(
			label='agraph classic-webview',
			 #url=os.environ['AGRAPH_URL'] + '/classic-webview#/repositories/'+repo+'/node/' + '<' + uri + '>'),
			 url=os.environ['AGRAPH_URL'] + '/classic-webview#/repositories/'+repo+'/node/' + n3),
			 
		dict(
			label='sparklis (as subject)',
			url=sp + urllib.parse.urlencode({
				'title': 'Hi',
				'endpoint': endpoint,# 'http://servolis.irisa.fr/dbpedia/sparql',
				'sparklis-query': f'[VId]Return(Det(Term(URI("{n3}")),Some(Triple(S,Det(An(7,Modif(Select,Unordered),Thing),None),Det(An(8,Modif(Select,Unordered),Thing),None)))))',
				'sparklis-path': 'DDDR'})
		),
		
		dict(
			label='sparklis (as object)',
			url=sp + urllib.parse.urlencode({
				'title': 'Hi',
				'endpoint': endpoint,# 'http://servolis.irisa.fr/dbpedia/sparql',
				'sparklis-query': f'[VId]Return(Det(Term(URI("{n3}")),Some(Triple(O,Det(An(7,Modif(Select,Unordered),Thing),None),Det(An(8,Modif(Select,Unordered),Thing),None)))))',
				'sparklis-path': 'DDDR'})								 
		),
	]
		





"""

notes

lists are easy, they will be one of the types of resources with a custom-built view component.
otoh, consider l:vec:
	we want to associate l:vec objects through kb:occurs_in.
	actually this might simply be done by the vec view component. (or rather some ifs on the backend)
	and that's propably fair, until some 'theory of equivalence of complex rdf objects' develops.

literals, otoh, could simply be made to be browseable
 - replace uri with node, trim(<>).. with some n3_parse, fix some errors, and you're browsing ?s ?p ?lit statements (probably not ?lit ?p ?o, those wouldn't exist in the store in the first place...)

but this brings a distinction/discrepancy between complex objects (l:vec) and literals -
	literals will be browseable by virtue of the browser,
	vec objects will be browseable by virtue of the view component.
	other complex objects wont, for example:
		find two equivalent report entries across different jobs
	
"""


# def prop_categories(result, all_props):
# 	cats = {}
# 	queryString = """
# 	PREFIX franzOption_defaultDatasetBehavior: <franz:rdf>
# 	
# 	SELECT ?p ?c 
# 	{	""" + " UNION ".join([f"{{{p} rdftab:category ?c . }}" for p in all_props]) + """} LIMIT 10000"""
# 	tupleQuery: agraph.TupleQuery = result['conn'].prepareTupleQuery(QueryLanguage.SPARQL, queryString)
# 	results: agraph.TupleQueryResult
# 	with tupleQuery.evaluate() as results:	
# 		for bindingSet in results:
# 			cats[bindingSet.getValue("p").getURI()] = bindingSet.getValue("g").getURI()
# 	return cats


	# for k,v in prop_categories(result, all_props).items():
	# 	for prop in result['props']:
	# 		if prop['p']['uri'] == k:
	# 			prop['category'] = dict(fake=v.split('#')[-1], uri=v)
	# 
	# category_order = dict(identificational=0, definitional=1, general=2, technical=3)
	# 
	# result['props'].sort(key=lambda x: (category_order.get(x['category']['fake']), x['p']['best'], x['o']['best'], x['g']['best']))
	# 			



# 
# 
# def assign_best_display(prop):
# 	assign_best_display2(prop['g'])
# 	assign_best_display2(prop['category'])
# 	assign_best_display2(prop['p'])
# 	assign_best_display2(prop['o'])

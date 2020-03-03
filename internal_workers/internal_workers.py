from c import app

import os
import rdflib
import rdflib.plugins.serializers.nquads
import urllib


def agc():
	#from franz.openrdf.repository.repository import Repository
	# from franz.openrdf.sail.allegrographserver import AllegroGraphServer
	from franz.openrdf.connect import ag_connect
	user = os.environ.get('AGRAPH_USER')
	passw = os.environ.get('AGRAPH_PASS')
	if user != None and passw != None:
		return ag_connect('a', host='localhost', port='10036', user=user, password=passw)
	else:
		print('agraph user and pass not provided, skipping')


@app.task
def put_doc_dump_into_triplestore(tmp_path):
	trig_fn = tmp_path + '/doc.trig'# or: trig_fn = report_by_key(response, 'doc.trig')
	nq_fn = tmp_path + '/doc.nq'
	g=rdflib.graph.ConjunctiveGraph()
	g.load(trig_fn, format='trig')
	generate_yed_file(g, tmp_path)
	g.serialize(nq_fn, format='nquads')
	c = agc()
	if c:
		c.addFile(nq_fn)


import pyyed


def generate_yed_file(g0, tmp_path):
	go = pyyed.Graph()
	added = set()
	for (s, p, o, c) in g0.quads(None):
		add_node(go, added, s)
		add_node(go, added, o)
		go.add_edge(s, o, label=p)
	go.write_graph(tmp_path + '/doc.yed.graphml', pretty_print=True)


prefixes = [
	('xml', 'http://www.w3.org/XML/1998/namespace#'),
	('xsd', 'http://www.w3.org/2001/XMLSchema#'),
	('l', 'https://rdf.lodgeit.net.au/v1/request#').


	]
prefixes.sort(key=len)


def add_node(go, added, x):
	if x not in added:
		added.add(x)

		kwargs = {}

		#parsed = urllib.parse.urlparse(x)
		#fragment = parsed.fragment
		#if fragment != '':

		for shorthand, uri in prefixes:
			if x.startswith(uri):
				kwargs['label'] = shorthand + x[len(uri):]
				break

		go.add_node(x, shape_fill="#DDDDDD", **kwargs)

from celery_module import app

import os, sys

import rdflib
import rdflib.plugins.serializers.nquads
import urllib


def agc():
	#from franz.openrdf.repository.repository import Repository
	# from franz.openrdf.sail.allegrographserver import AllegroGraphServer
	from franz.openrdf.connect import ag_connect
	user = app.conf.AGRAPH_SECRET_USER
	passw = app.conf.AGRAPH_SECRET_PASSWORD
	if user != None and passw != None:
		return ag_connect('a', host='localhost', port='10036', user=user, password=passw)
	else:
		print('agraph user and pass not provided, skipping')


@app.task
def put_doc_dump_into_triplestore(tmp_path):
	trig_fn = tmp_path + '/doc.trig'# or: trig_fn = report_by_key(response, 'doc.trig')
	nq_fn = tmp_path + '/doc.nq'
	g=rdflib.graph.ConjunctiveGraph()
	print("load "+trig_fn + "...", file=sys.stderr)
	g.load(trig_fn, format='trig')
	#generate_yed_file(g, tmp_path)
	print("write "+nq_fn + "...", file=sys.stderr)
	g.serialize(nq_fn, format='nquads')
	print("agc()...", file=sys.stderr)
	c = agc()
	if c:
		print("c.addFile(nq_fn)...", file=sys.stderr)
		#c.addFile(nq_fn)


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
	('l', 'https://rdf.lodgeit.net.au/v1/request#')


	]
prefixes.sort(key=len)


def add_node(go, added, x):
	if x not in added:
		added.add(x)
		print("len(added): "+str(len(added)) + "...", file=sys.stderr)

		kwargs = {}

		#parsed = urllib.parse.urlparse(x)
		#fragment = parsed.fragment
		#if fragment != '':

		for shorthand, uri in prefixes:
			if x.startswith(uri):
				kwargs['label'] = shorthand + x[len(uri):]
				break

		# uEd can display a (clickable?) URL, but that has to be specified like:
		# <data key="d3" xml:space="preserve"><![CDATA[http://banana.pie]]></data>
		# if you want to see it, go to yEd, assign the URL property on a node and save the file.
		# etree doesn't support writing out CDATA.
		# workarounds:
		# https://stackoverflow.com/questions/174890/how-to-output-cdata-using-elementtree
		# best bet: lxml has a compatible api(?)

		go.add_node(x, shape_fill="#DDDDDD", **kwargs)

	# at any case, at about 1000 nodes, since we're building up the xml dom in memory, this script slows to a crawl. So we need a custom solution.
	# however, yed itself is not suitable for thousands of nodes: https://yed.yworks.com/support/qa/11879/maximum-number-of-nodes-that-yed-can-handle

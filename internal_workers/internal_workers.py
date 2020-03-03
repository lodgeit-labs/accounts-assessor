from c import app

import os
import rdflib
import rdflib.plugins.serializers.nquads



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
	g.serialize(nq_fn, format='nquads')
	c = agc()
	if c:
		c.addFile(nq_fn)


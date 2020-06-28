from celery_module import app

import sys, os
import rdflib
import rdflib.plugins.serializers.nquads
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../triplestore_access')))
import agraph




@app.task
def postprocess_doc(tmp_path):
	print('postprocess_doc...')
	g, nq_fn = generate_doc_nq_from_trig(tmp_path)
	put_doc_dump_into_triplestore(nq_fn)
	#generate_yed_file(g, tmp_path)
	#generate_gl_json(g)

def generate_doc_nq_from_trig(tmp_path):
	trig_fn = tmp_path + '/doc.trig'# or: trig_fn = report_by_key(response, 'doc.trig')
	nq_fn = tmp_path + '/doc.nq'
	g=rdflib.graph.ConjunctiveGraph()
	print("load "+trig_fn + "...", file=sys.stderr)
	g.load(trig_fn, format='trig')
	print("write "+nq_fn + "...", file=sys.stderr)
	g.serialize(nq_fn, format='nquads')
	return g, nq_fn

def put_doc_dump_into_triplestore(nq_fn):
	print("agc()...", file=sys.stderr)
	c = agraph.agc()
	if c:
		print("c.addFile(nq_fn)...", file=sys.stderr)
		c.addFile(nq_fn)
		print("c.addFile(nq_fn) done.", file=sys.stderr)

def report_by_key(response, key):
	for i in response['reports']:
		if i['key'] == key:
			return i['val']['url']




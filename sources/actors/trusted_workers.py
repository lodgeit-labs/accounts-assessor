#sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common/libs/misc')))
import sys, os
from pathlib import Path

import rdflib
import rdflib.plugins.serializers.nquads
import agraph
from tasking import remoulade
import logging



log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.debug("debug from trusted_workers.py")
log.info("info from trusted_workers.py")
log.warning("warning from trusted_workers.py")



#@remoulade.actor(queue='postprocessing', priority=1, time_limit=1000*60*60*24*365)
@remoulade.actor(priority=1, time_limit=1000*60*60*24*365, queue_name='postprocessing')
def postprocess_doc(tmp_path):
	tmp_path = Path(tmp_path)
	# fixme, need to find the right file
	log.info('postprocess_doc...')
	
	g = load_doc_dump(tmp_path)
	if g:
		nq_fn = generate_doc_nq_from_trig(g, tmp_path)		
		put_doc_dump_into_triplestore(nq_fn)
		#generate_yed_file(g, tmp_path)
		#generate_gl_json(g)
remoulade.declare_actors([postprocess_doc])



def load_doc_dump(tmp_path):
	trig_fn = tmp_path / '000000_doc_final.trig'
	# or: trig_fn = report_by_key(response, 'doc.trig')

	if trig_fn.is_file():
		g=rdflib.graph.ConjunctiveGraph()
		log.debug(f"load {trig_fn} ...")
		g.parse(trig_fn, format='trig')
		log.debug(f"load {trig_fn} done.")
		return g


def generate_doc_nq_from_trig(g, tmp_path):
	nq_fn = tmp_path / 'doc.nq'
	log.debug(f"write {nq_fn} ...")
	g.serialize(nq_fn, format='nquads')
	return nq_fn



def put_doc_dump_into_triplestore(nq_fn):
	log.debug("agc()...")
	c = agraph.agc()
	if c:
		log.debug("c.addFile(nq_fn)...")
		c.addFile(str(nq_fn))
		log.debug("c.addFile(nq_fn) done.")



def report_by_key(response, key):
	for i in response['reports']:
		if i['key'] == key:
			return i['val']['url']



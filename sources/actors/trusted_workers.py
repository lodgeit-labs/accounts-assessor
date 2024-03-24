#sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common/libs/misc')))
import subprocess
import sys, os
import urllib
from pathlib import Path, PosixPath
from shutil import make_archive

import rdflib
import rdflib.plugins.serializers.nquads
import agraph
from tasking import remoulade
import logging

from tmp_dir_path import get_tmp_directory_absolute_path, ln

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.debug("debug from trusted_workers.py")
log.info("info from trusted_workers.py")
log.warning("warning from trusted_workers.py")





@remoulade.actor(priority=1, time_limit=1000*60*60*24*365, queue_name='postprocessing')
def postprocess(job, request_directory, tmp_name, tmp_path, uris, user, public_url):
	tmp_path = Path(tmp_path)
	log.info('postprocess...')
	
	g = load_doc_dump(tmp_path)
	if g:
		nq_fn = generate_doc_nq_from_trig(g, tmp_path)
		put_doc_dump_into_triplestore(nq_fn, uris, user)
		#generate_yed_file(g, tmp_path)
		#generate_gl_json(g)
		
		# todo export xlsx's

		result_tmp_directory_name = uris.get('result_tmp_directory_name', '')
		
		create_html_with_link(tmp_path/'job.html', dict(
			Job=f'../{job}',
			Inputs=f'../{request_directory}',
			Archive=f'../../view/archive/{job}/{tmp_name}',
			Rdftab='/static/rdftab/rdftab.html?'+urllib.parse.urlencode(
					{
						'node':						'<'+	public_url + '/rdf/results/' + result_tmp_directory_name+'/>',
						'focused-graph':				public_url + '/rdf/results/' + result_tmp_directory_name+'/default'
					}
				)
			)
		)
		


@remoulade.actor
def print_actor_error(actor_name, exception_name, message_args, message_kwargs):
  log.error(f"Actor {actor_name} failed:")
  log.error(f"Exception type: {exception_name}")
  log.error(f"Message args: {message_args}")
  log.error(f"Message kwargs: {message_kwargs}")



remoulade.declare_actors([print_actor_error, postprocess])


def create_html_with_link(filename, links):
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <body>"""
    for k,v in links.items():
    	html_content += f"""<a href="{v}">{k}</a><br>"""
    html_content += """</body>
    </html>
    """
    with open(filename, 'w') as file:
        file.write(html_content)
        

# @remoulade.actor(priority=1, time_limit=1000*60*60*24*365, queue_name='postprocessing')
# def archive(tmp_name, tmp_path, uris, user):
# 	pass
# 
# remoulade.declare_actors([archive])



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



def put_doc_dump_into_triplestore(nq_fn, uris, user):
	log.debug("agc(nq_fn=%s, uris=%s, user=%s)...", nq_fn, uris, user)
	
	c = agraph.agc(agraph.repo_by_user(user))
	if c:
		log.debug("c.addFile(nq_fn)...")
		c.addFile('../static/kb.trig')
		c.addFile(str(nq_fn))
		log.debug("c.addFile(nq_fn) done.")

		if uris:
			# add prefixes
			result_prefix = uris['result_tmp_directory_name'].split('.')[-1]
			# ^see create_tmp_directory_name
			prx = result_prefix, uris['result_data_uri_base']
			log.debug("c.setNamespace(%s)...", prx)
			c.setNamespace(*prx)



def report_by_key(response, key):
	for i in response['reports']:
		if i['key'] == key:
			return i['val']['url']



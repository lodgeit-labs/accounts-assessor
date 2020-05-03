#!/usr/bin/env python3

import threading, json, time, click, subprocess, shlex, shutil, ntpath, os, sys

import internal_workers

class AtomicInteger():
	""" https://stackoverflow.com/questions/23547604/python-counter-atomic-increment """
	def __init__(self, value=0):
		self._value = value
		self._lock = threading.Lock()

	def inc(self):
		with self._lock:
			self._value += 1
			return self._value

	def dec(self):
		with self._lock:
			self._value -= 1
			return self._value


	@property
	def value(self):
		with self._lock:
			return self._value

	@value.setter
	def value(self, v):
		with self._lock:
			self._value = v
			return self._value


server_started_time = time.time() # in theory, this could collide, fixme
client_request_id = AtomicInteger()


def files_in_dir(dir):
	result = []
	for filename in os.listdir(dir):
		filename2 = '/'.join([dir, filename])
		if os.path.isfile(filename2):
			result.append(filename2)
	return result

@click.command()
@click.argument('request_files', nargs=-1)
@click.option('-d', '--dev_runner_options', type=str)
@click.option('-p', '--prolog_flags', type=str)
@click.option('-s', '--server_url', type=str, default='http://localhost:7778')
@click.option('-dbgl', '--debug_loading', type=bool, default=False)
@click.option('-dbg', '--debug', type=bool, default=False)
@click.option('-hlt', '--halt', type=bool, default=True)

def run(debug_loading, debug, request_files, dev_runner_options, prolog_flags, server_url, halt):
	if dev_runner_options == None:
		dev_runner_options = ''
	request_files2 = [os.path.abspath(os.path.expanduser(f)) for f in request_files]
	tmp_directory_name, tmp_directory_absolute_path = create_tmp()
	if len(request_files2) == 1 and os.path.isdir(request_files2[0]):
		files = files_in_dir(request_files2[0])
	else:
		files = request_files2
	files2 = []
	for f in files:
		tmp_fn = os.path.abspath('/'.join([tmp_directory_absolute_path, ntpath.basename(f)]))
		shutil.copyfile(f,tmp_fn)
		files2.append(tmp_fn)
	msg = {
		"method": "calculator",
		"params": {
			"server_url": server_url,
			"tmp_directory_name": tmp_directory_name,
			"request_files": files2}
	}
	call_prolog(msg=msg, dev_runner_options=shlex.split(dev_runner_options), prolog_flags=prolog_flags, debug_loading=debug_loading, debug=debug, halt=halt)


def call_prolog(msg, dev_runner_options=[], prolog_flags='true', make_new_tmp_dir=False, debug_loading=None, debug=None, halt=True):




	# comment(RDF_EXPLORER_1_BASE, comment, 'base of uris to show to user in generated html')
	rdf_explorer_base = 'http://dev-node.uksouth.cloudapp.azure.com:10036/#/repositories/a/node/'
	rdf_namespace_base = 'http://dev-node.uksouth.cloudapp.azure.com/rdf/'
	request_uri = rdf_namespace_base + 'requests/' + msg['params']["tmp_directory_name"]

	msg['params']["request_uri"] = request_uri
	msg['params']["rdf_namespace_base"] = rdf_namespace_base
	msg['params']["rdf_explorer_bases"] = [rdf_explorer_base]

	if True:#make_new_tmp_dir:
		msg['params']['tmp_directory_name'],tmp_path = create_tmp()
		with open(os.path.join(tmp_path, 'info.txt'), 'w') as info:
			info.write(str(msg))
			info.write('\n')



	# working directory. Should not matter for the prolog app, since everything in the prolog app uses (or should use) lib/search_paths.pl,
	# and dev_runner uses tmp_file_stream.
	
	os.chdir(git("server_root"))



		
	# SWI_HOME_DIR is the (system) directory where swipl has put it's stuff during installation
	# not sure why this needs to be set, since swipl should find it based on argv, but that's not happening, see notes <- what notes?
	
	#if os.path.expanduser('~') == '/var/www':
	#os.environ.putenv('SWI_HOME_DIR', '/usr/lib/swi-prolog')
	




	# an unresolved problem under mod_wsgi is finding swipl libraries (as would be installed by user in their home dir with pack_install).
	# see https://www.swi-prolog.org/pldoc/doc_for?object=file_search_path/2
	path_flags = []# '-g', "assertz(file_search_path(library, '/home/demo/.local/share/swi-prolog/pack/'))"]




	#todo, probably take it from env
	#if debug_loading == None:
	#if debug == None:

	# construct the command line

	if debug_loading:
		entry_file = 'lib/debug_loading_rpc_server.pl'
	else:
		entry_file = "lib/rpc_server.pl"

	if debug:
		debug_args = ['-dtrue']
		debug_goal = 'debug,'
	else:
		debug_args = ['-dfalse']
		debug_goal = ''

	if halt:
		halt_goal = ',halt'
	else:
		halt_goal = ''

	print_cmd_to_swipl_stdin = False

	input = json.dumps(msg)

	swipl = ['swipl'] + path_flags
	cmd0 = swipl + ['-s', git("lib/dev_runner.pl"),'--problem_lines_whitelist',git("misc/problem_lines_whitelist")] + debug_args + ["-s", git(entry_file)]
	cmd1 = dev_runner_options

	if print_cmd_to_swipl_stdin:
		goal = ',lib:process_request_rpc_cmdline'
	else:
		goal = ",lib:process_request_rpc_cmdline_json_text('" + (input).replace('"','\\"') + "')"

	cmd2 = ['-g', debug_goal + prolog_flags + goal+halt_goal]
	cmd = cmd0 + cmd1 + cmd2
	print(' '.join(cmd))
	#print(cmd)

	
	if print_cmd_to_swipl_stdin:
		print('<<', input)

	# if you want to see current env:
	#import sys
	#print(sys.path)
	#p = subprocess.Popen(['bash', '-c', 'export'], universal_newlines=True)
	#p.communicate()

	try:
		if print_cmd_to_swipl_stdin:
			p = subprocess.Popen(cmd, universal_newlines=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
			(stdout_data, stderr_data) = p.communicate(input = input)
		else:
			p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE)
			(stdout_data, stderr_data) = p.communicate()
	except FileNotFoundError as e:
		print(
			"if system PATH is messed up, maybe you're running the server from venv, and activating the venv second time, from run_common0.sh, messes it up")
		raise

	print("result from prolog:")
	print(stdout_data)
	print("end of result from prolog.")
	try:
		rrr = json.loads(stdout_data)
		internal_workers.put_doc_dump_into_triplestore.apply_async((tmp_path,))
		return msg['params']['tmp_directory_name'], rrr
	except json.decoder.JSONDecodeError as e:
		print(e)
		return msg['params']['tmp_directory_name'], {'status':'error'}


def report_by_key(response, key):
	for i in response['reports']:
		if i['key'] == key:
			return i['val']['url']


def git(Suffix = ""):
	""" get git repo root path """
	here = os.path.dirname(__file__)
	#print(here)
	r = os.path.normpath(os.path.join(here, '../', Suffix))
	#print(r)
	return r

def create_tmp_directory_name():
	""" create a unique name """
	return str(server_started_time) + '.' + str(client_request_id.inc())

def get_tmp_directory_absolute_path(name):
	""" append the unique name to tmp/ path """
	return os.path.abspath(os.path.join(git('server_root/tmp'), name))
	
def create_tmp():
	name = create_tmp_directory_name()
	path = os.path.normpath(get_tmp_directory_absolute_path(name))
	os.mkdir(path)
	subprocess.call(['/bin/rm', get_tmp_directory_absolute_path('last')])
	subprocess.call(['/bin/ln', '-s', get_tmp_directory_absolute_path(name), get_tmp_directory_absolute_path('last')])
	return name,path



if __name__ == '__main__':
	run()


#how to control debugging?



	#for i in g.quads(None):
	#		print(i)
"""sparql_store = SPARQLUpdateStore()
	sparql_store.open((None,
	sparql_graph = rdflib.graph.ConjunctiveGraph()
	for spog in g.quads(None):
		sparql_graph.

		from rdflib.plugins.stores.sparqlstore import SPARQLUpdateStore
	s=SPARQLUpdateStore()
	from SPARQLWrapper import BASIC
	s.setHTTPAuth(BASIC)
	s.setCredentials()
	queryString = "SELECT * WHERE { ?s ?p ?o. }"
	s.open(('http://localhost:10036/#/repositories/a',)*2)
	s.query(queryString)
		"""
def ag_query():
	c = agc()
	from franz.openrdf.query.query import QueryLanguage
	query_string = "SELECT ?s ?p ?o  WHERE {?s ?p ?o .}"
	tuple_query = c.prepareTupleQuery(QueryLanguage.SPARQL, query_string)
	result = tuple_query.evaluate()
	print(result)
	with result:
		for binding_set in result:
			s = binding_set.getValue("s")
			p = binding_set.getValue("p")
			o = binding_set.getValue("o")
			print("%s %s %s" % (s, p, o))



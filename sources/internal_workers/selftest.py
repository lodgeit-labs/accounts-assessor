


import logging
l = logging.getLogger()
l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())





import json, subprocess, os, sys, shutil, shlex
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from agraph import agc, bn_from_string, RDF
from franz.openrdf.repository.repositoryconnection import RepositoryConnection
from dotdict import Dotdict




from rq import Queue
from redis import Redis
redis_conn = Redis(os.environ.get('SECRET__REDIS_HOST', 'localhost'))
q = Queue('selftest', connection=redis_conn)



def start_selftest_session(target_server_url):
	a: RepositoryConnection = agc()
	selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')
	task = generateUniqueUri(a, 'task')
	a.addTriple(task, RDF.TYPE, selftest.Session)
	a.addTriple(task, selftest.target_server_url, target_server_url)
	task_str = str(task)
	job = q.enqueue('invoke_rpc.call_prolog2', msg={"method": "testcase_permutations", "params": {}}, on_success=after_generate_testcase_permutations, meta={'task_str':task_str})
	return task_str, job


def after_generate_testcase_permutations(job, connection, permutations, *args, **kwargs):
	q.enqueue(add_testcase_permutations, job.meta['task_str'], permutations, on_success=after_add_testcase_permutations, meta=job.meta)

def after_add_testcase_permutations(job, connection, _, *args, **kwargs):
	q.enqueue(run_outstanding_testcases, job.meta['task_str'])




def add_testcase_permutations(task_str, permutations):
	task = bn_from_string(task_str)

	a = agc()
	selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')
	#logging.getLogger().warn(permutations)
	for p0 in permutations:

		p = parse_permutation(p0)
		logging.getLogger().info((p0))
		testcase = agc().createBNode()

		#tr()
		if 'priority' not in p:
			p.priority = 0

		a.addTriple(task, selftest.has_testcase, testcase)
		a.addTriple(testcase, selftest.priority, p.priority)
		import time
		p['ts'] = time.ctime()
		dd = p._dict
		jj = json.dumps(dd, indent=4)
		a.addTriple(testcase, selftest.json, jj)




def run_outstanding_testcases(task_str):
	"""continue a particular testing session by running the next testcase and recursing"""
	task = bn_from_string(task_str)
	a = agc()
	#FILTER ( !EXISTS {?testcase selftest:done true})
	query = a.prepareTupleQuery(query="""
	SELECT DISTINCT ?testcase ?json WHERE {
		?session selftest:has_testcase ?testcase . 
		FILTER NOT EXISTS {?testcase selftest:done true} 
		?testcase selftest:priority ?priority .
		?testcase selftest:json ?json .        
	}
	ORDER BY DESC (?priority)	
	LIMIT 1
	""")
	query.setBinding('?session', task)
	with query.evaluate() as result:
		for bindings in result:
			tc = bindings.getValue('testcase')
			txt = bindings.getValue('json').getValue()
			logging.getLogger().info(((txt)))
			jsn = json.loads(txt)
			js = Dotdict(**jsn)
			q.enqueue(do_testcase, tc, js)


def do_testcase(testcase, json):
	logging.getLogger().info(('do_testcase:',testcase, json))
# 			if i.mode == 'remote':
# 				result = run_remote_test(i)
# 			else:
# 				result = run_local_test(i)
	q.enqueue(run_outstanding_testcases, session)




#
# def process_response(response):
# 	for report in response['reports']:
# 		# assert it into the db
# 		# grab the file
# 		# do the comparisons
# 		pass
#
#
# def reopen_last_testing_session():
# 	pass



# @app.task(acks_late=acks_late)
# def self_test():
# 	"""
# 	This is called by celery, and may be killed and called repeatedly until it succeeds.
# 	Celery keeps track of the task.
# 	It will only succeed once it has ran all tests
# 	This means that it's possible to amend a running self_test by saving more testcases.
# 	We will save the results of each test ran.
# 	first, we call prolog to generate all test permutations
# 	"""
#
# 	"""
# 	query:
# 		?this has_celery_uuid uuid
# 	if success:
# 		"task with UUID <uuid> already exists"
# 	else:
# 		this = unique_uri()
# 		insert(this has_celery_uuid uuid)
#
# 	permutations = celery_app.signature('invoke_rpc.call_prolog').apply_async({
# 		'msg': {"method": "self_test_permutations"}
# 	}).get()
# 	for i in permutations:
# 		# look the case up in agraph
# 		# this self test should have an uri
# 		agraph query:
# 			this has_test [
# 			has_permutation i;
# 			done true;]
# 		if success:
# 			continue
# 		else:
# 			test = unique_uri()
# 			insert(test has_permutation i)
# 			if i.mode == 'remote':
# 				result = run_remote_test(i)
# 			else:
# 				result = run_local_test(i)
#
# 		'http://xxxself_testxxx is finished.'
# 	return "ok"
# 	"""


def parse_permutation(p0):
	a = {}
	#logging.getLogger().info(p0)
	for i in p0:
		k,v = list(i.items())[0]
		a[k] = v
	return Dotdict(a)



def continue_outstanding_selftest_session():
	"""pick a session"""
	a = agc()
	with a.prepareTupleQuery(query="""
	SELECT DISTINCT ?session WHERE {
		?session rdf:type selftest:Session .
		FILTER NOT EXISTS {?session selftest:closed true}
	}
	""").evaluate() as result:
		result.enableDuplicateFilter()
		for bindings in result:
			return run_outstanding_testcases(str(bindings.getValue('session')))



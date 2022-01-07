import typing



import logging
l = logging.getLogger()
l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())



import json, subprocess, os, sys, shutil, shlex, requests
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from agraph import agc, RDF, generateUniqueUri
from franz.openrdf.repository.repositoryconnection import RepositoryConnection
from franz.openrdf.model.value import URI
from dotdict import Dotdict



from rq import Queue
from redis import Redis
redis_conn = Redis(os.environ.get('SECRET__REDIS_HOST', 'localhost'))
from rq_myjob import MyJob
q = Queue('selftest', job_class=MyJob, connection=redis_conn, default_timeout=-1, is_async=os.environ.get('RQ_ASYNC',True))



def start_selftest_session(target_server_url):
	a: RepositoryConnection = agc()
	selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')
	session = generateUniqueUri(a, 'session')
	a.addTriple(session, RDF.TYPE, selftest.Session)
	a.addTriple(session, selftest.target_server_url, target_server_url)
	job = q.enqueue('invoke_rpc.call_prolog', msg={"method": "testcase_permutations", "params": {'target_server_url':target_server_url}}, on_success=after_generate_testcase_permutations, meta={'session':str(session)})
	return session, job



def after_generate_testcase_permutations(job, connection, permutations: dict, *args, **kwargs):
	if permutations['status'] == 'ok':
		q.enqueue(add_testcase_permutations, job.meta['session'], permutations['result'], on_success=after_add_testcase_permutations, meta=job.meta)
	else:
		raise Exception(permutations)



def after_add_testcase_permutations(job, connection, _, *args, **kwargs):
	session = job.meta['session']
	q.enqueue(run_outstanding_testcases, session)



def add_testcase_permutations(session, permutations):
	session = URI(session)

	a = agc()
	selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')
	#logging.getLogger().warn(permutations)
	for p0 in permutations:

		p = ordered_json_to_dict(p0)
		#logging.getLogger().info((p0))
		testcase = generateUniqueUri(a, 'testcase')

		#tr()
		if 'priority' not in p:
			p['priority'] = 0

		a.addTriple(session, selftest.has_testcase, testcase)
		a.addTriple(testcase, selftest.priority, p['priority'])
		import time
		p['ts'] = time.ctime()
		jj = json.dumps(p, indent=4)
		a.addTriple(testcase, selftest.json, jj)



def run_outstanding_testcases(session):
	"""continue a particular testing session by running the next testcase and recursing"""
	session = URI(session)
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
	#LIMIT 1
	""")
	query.setBinding('session', session)
	with query.evaluate() as result:
		result = list(result)
		logging.getLogger().info(result)
		for bindings in result:
			tc = bindings.getValue('testcase')
			txt = bindings.getValue('json').getValue()
			logging.getLogger().info(f'enqueue(do_testcase: {txt}')
			jsn = json.loads(txt)
			q.enqueue(do_testcase, str(tc), jsn)



def do_testcase(testcase, json):
	testcase = URI(testcase)
	logging.getLogger().info(f'do_testcase: {testcase}')
	try:
		result = run_test(Dotdict(json))
	except e:
		print(e)
	#q.enqueue(run_outstanding_testcases, session)



def run_test(test):
	logging.getLogger().info(f'{test.target_server_url}')
	if test.type=='json_endpoint_test':
		res = requests.post(url=test.target_server_url + test.api_uri, json=test.post_data)
		print(res.json())







def ordered_json_to_dict(p0):
	a = {}
	#logging.getLogger().info(p0)
	for i in p0:
		k,v = list(i.items())[0]
		a[k] = v
	return a


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





# def continue_outstanding_selftest_session():
# 	"""pick a session"""
# 	a = agc()
# 	with a.prepareTupleQuery(query="""
# 	SELECT DISTINCT ?session WHERE {
# 		?session rdf:type selftest:Session .
# 		FILTER NOT EXISTS {?session selftest:closed true}
# 	}
# 	""").evaluate() as result:
# 		result.enableDuplicateFilter()
# 		for bindings in result:
# 			return run_outstanding_testcases(str(bindings.getValue('session')))





# from rq import get_current_job
# job = get_current_job()

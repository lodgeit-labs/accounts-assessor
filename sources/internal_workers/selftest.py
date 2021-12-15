

import logging, json, subprocess, os, sys, shutil, shlex
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from agraph import agc, bn_from_string, RDF


from celery_module import app



import celery
import celeryconfig
celery_app = celery.Celery(config_source = celeryconfig)




@app.task(acks_late=True)
def assert_selftest_session(task, target_server_url):

	a = agc()
	selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')

	bn = bn_from_string(task)
	a.add(bn, RDF.TYPE, selftest.Session)
	a.add(bn, selftest.target_server_url, target_server_url)
	add_testcase_permutations(task)
	return task


def add_testcase_permutations(task):

	testcase_permutations = celery_app.signature('invoke_rpc.call_prolog').apply_async([{"method": "testcase_permutations", "params": {}}]).get()

	a = agc()
	selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')

	for p in testcase_permutations:

		testcase = agc().createBNode()

		a.add(task, selftest.has_testcase, testcase)
		a.add(testcase, selftest.priority, p.priority)
		a.add(testcase, selftest.json, p)




@app.task(acks_late=True)
def continue_selftest_session():
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
			return continue_selftest_session2(str(bindings.getValue('session')))


@app.task(acks_late=True)
def continue_selftest_session2(session):
	"""continue a particular testing session"""
	a = agc()
	#FILTER ( !EXISTS {?testcase selftest:done true})
	q = a.prepareTupleQuery(query="""
	SELECT DISTINCT ?testcase WHERE {
		?session selftest:has_testcase ?testcase . 
		FILTER NOT EXISTS {?testcase selftest:done true} 
		?testcase selftest:priority ?priority .
		?testcase selftest:json ?json .        
	}
	ORDER BY DESC (?priority)	
	LIMIT 1
	""")
	q.setBinding('?session', session)
	with q.evaluate() as result:
		logging.getLogger().info(((result)))
		for bindings in result:
			tc = bindings.getValue('testcase')
			js = Dotdict(bindings.getValue('json'))
			(do_testcase(tc, js) | continue_selftest_session2(session))()
			return


@app.task(acks_late=True)
def do_testcase(testcase, json):
	logging.getLogger().info((('do_testcase:',testcase, json)))
# 			if i.mode == 'remote':
# 				result = run_remote_test(i)
# 			else:
# 				result = run_local_test(i)


	continue_selftest_session2.apply_async(args=(session,))

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



# @app.task(acks_late=True)
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

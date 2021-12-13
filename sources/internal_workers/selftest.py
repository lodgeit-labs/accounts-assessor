

import logging, json, subprocess, os, sys, shutil, shlex
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from agraph import agc


from celery_module import app



import celery
import celeryconfig
celery_app = celery.Celery(config_source = celeryconfig)


#
# @app.task(acks_late=True)
# def start_selftest_session(task, target_server_url):
# 	logging.getLogger().info(f'start_selftest_session {target_server_url=}')








@app.task(acks_late=True)
def assert_selftest_session(task, target_server_url):
	# first we assert the longtask into the db
	a = agc()
	selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')
	task = bn_from_string(task)
	a.add(task, RDF.TYPE, selftest.Session)
	a.add(task, selftest.target_server_url, target_server_url)



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
			return continue_testing_session2(bindings.getValue('session'))



def continue_testing_session2(session):
	"""continue a particular testing session"""
	a = agc()
	with a.prepareTupleQuery(query="""
    SELECT DISTINCT ?testcase WHERE {
        ?session selftest:has_testcase ?testcase .
        NOT EXISTS {?testcase selftest:done true} .
        ?testcase selftest:priority ?priority .
        ?testcase selftest:data ?data .        
    }
    ORDER BY ?priority DESCENDING
    
    """).evaluate() as result:
		for bindings in result:
			return do_testcase(Dotdict(bindings.getValue('testcase')), Dotdict(bindings.getValue('data')))


def do_testcase(testcase, data):
	print(('do_testcase:',testcase, data))
# 			if i.mode == 'remote':
# 				result = run_remote_test(i)
# 			else:
# 				result = run_local_test(i)


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


def add_testcase_permutations(task):
	for p in testcase_permutations():
		a.add(task, selftest.has_testcase, Tc)

	return celery_app.signature('invoke_rpc.call_prolog').apply_async([{"method": "testcase_permutations", "params": {}}]).get()[1]


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

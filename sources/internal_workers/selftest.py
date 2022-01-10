import typing



import logging

l = logging.getLogger()
l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())



import remoulade
from remoulade.brokers.rabbitmq import RabbitmqBroker
rabbitmq_broker = RabbitmqBroker(url="amqp://localhost")
remoulade.set_broker(rabbitmq_broker)



import json, subprocess, os, sys, shutil, shlex, requests
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from agraph import agc, RDF, generateUniqueUri
from franz.openrdf.repository.repositoryconnection import RepositoryConnection
from franz.openrdf.model.value import URI
from dotdict import Dotdict
from invoke_rpc import call_prolog



def start_selftest_session(target_server_url):
	a: RepositoryConnection = agc()
	selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')
	session = generateUniqueUri(a, 'session')
	a.addTriple(session, RDF.TYPE, selftest.Session)
	a.addTriple(session, selftest.target_server_url, target_server_url)

	start_selftest_session2.send(str(session), target_server_url)

	return session

@remoulade.actor
def start_selftest_session2(session, target_server_url):
	msg = {"method": "testcase_permutations", "params": {'target_server_url':target_server_url}}
	res = call_prolog(msg)
	if res['status'] == 'ok':
		add_testcase_permutations(session, res['result'])
	else:
		raise Exception(res)
	run_outstanding_testcases(session)




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


@remoulade.actor
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
			do_testcase.send(str(tc), jsn)



@remoulade.actor
def do_testcase(testcase, json):
	testcase = URI(testcase)
	logging.getLogger().info(f'do_testcase: {testcase}')
	result = run_test(Dotdict(json))



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







remoulade.declare_actors([start_selftest_session2, run_outstanding_testcases, do_testcase])

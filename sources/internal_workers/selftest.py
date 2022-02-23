import typing
import logging
l = logging.getLogger()
l.setLevel(logging.DEBUG)
#l.addHandler(logging.StreamHandler())
import json, subprocess, os, sys, shutil, shlex, requests
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tasking import remoulade
from requests.adapters import HTTPAdapter
from agraph import agc, RDF, generateUniqueUri
from franz.openrdf.model.value import URI
from dotdict import Dotdict
from invoke_rpc import call_prolog
from pydantic import BaseModel
from typing import *



class TestData(BaseModel):
	target_server_url: str
	type: str

class JsonEndpointTestData(TestData):
	api_uri: str
	post_data: dict
	result_text: str

class CalculatorTestData(TestData):
	testcase: str
	mode: Optional[str]
	die_on_error: Optional[bool]



testcases_query1 = """
	SELECT DISTINCT ?testcase ?json WHERE 
	{
		%s selftest:has_testcase ?testcase . 
		FILTER NOT EXISTS {?testcase selftest:done true} .
		?testcase selftest:priority ?priority .
		?testcase selftest:index ?index .
		?testcase selftest:json ?json .        
	}
	ORDER BY ASC (?index)
	ORDER BY DESC (?priority)	
	#LIMIT 5
	"""



a = agc()
selftest = a.namespace('https://rdf.lodgeit.net.au/v1/selftest#')
kb = a.namespace('https://rdf.lodgeit.net.au/v1/kb#')



def start_selftest_session(target_server_url):
	session = generateUniqueUri('session')
	a.addTriple(session, RDF.TYPE, selftest.Session)
	a.addTriple(session, kb.ts, time())
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

	#logging.getLogger().warn(permutations)
	index = 0
	for p0 in permutations:

		p = ordered_json_to_dict(p0)
		#logging.getLogger().info((p0))
		testcase = generateUniqueUri('testcase')

		#tr()
		if 'priority' not in p:
			p['priority'] = 0
		p['index'] = index
		index += 1

		a.addTriple(session, selftest.has_testcase, testcase)
		a.addTriple(testcase, selftest.priority, p['priority'])
		a.addTriple(testcase, selftest.index, p['index'])
		import time
		p['ts'] = time.ctime()
		jj = json.dumps(p, indent=4)
		a.addTriple(testcase, selftest.json, jj)


@remoulade.actor
def run_outstanding_testcases(session):
	"""continue a particular testing session by running the next testcase and recursing"""
	session = URI(session)
	#FILTER ( !EXISTS {?testcase selftest:done true})
	query = a.prepareTupleQuery(query=(testcases_query1 % '?session'))
	query.setBinding('session', session)
	for bindings in query.evaluate():
		tc = bindings.getValue('testcase')
		txt = bindings.getValue('json').getValue()
		logging.getLogger().info(f'enqueue(do_testcase: {txt}')
		jsn = json.loads(txt)
		do_testcase.send(str(tc), jsn)



def last_session():
	a = a.prepareTupleQuery(query="""
	SELECT DISTINCT ?session WHERE {
		?session kb:ts ?ts .
	}
	ORDER BY DESC (?ts)	
	LIMIT 1
	""").
	for bindings in query.evaluate():
		return bindings.getValue('session')



@remoulade.actor
def do_testcase(testcase_uri, testcase_json):
	testcase_uri = URI(testcase_uri)
	logging.getLogger().info(f'do_testcase: {testcase_uri}')
	test = TestData(**testcase_json)
	if test.type=='json_endpoint_test':
		test = JsonEndpointTestData(**testcase_json)
		logging.getLogger().info(f'requests.post(url={test.target_server_url + test.api_uri}, json={test.post_data})....')
		try:
			res: requests.Response = post(url=test.target_server_url + test.api_uri, json=test.post_data, timeout=123)
		except Exception as e:
			logging.getLogger().info(e)
			a.addTriple(testcase_uri, selftest.has_failure, str(e))
			return
		logging.getLogger().info(jsn)
		logging.getLogger().info(jsn.result_text)
		expected = json.loads(jsn.result_text)
		actual = res.json()
		# todo json result comparison!
		# if expected == actual

		a.addTriple(testcase_uri, selftest.has_success, true)
	else:
		print('not implemented')


def post(url, json, timeout) -> requests.Response:
	s = requests.Session()
	a = HTTPAdapter(xxxtotal=20, backoff_factor=1,  allowed_methods=frozenset(['GET', 'POST']), status_forcelist=[ 500, 502, 503, 504, 521])
	s.mount('http://', a)
	s.mount('https://', a)
	return s.post(url, json, timeout)


def ordered_json_to_dict(p0):
	d = {}
	for i in p0:
		k,v = list(i.items())[0]
		d[k] = v
	return d


remoulade.declare_actors([start_selftest_session2, run_outstanding_testcases, do_testcase])


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




#
# def continue_outstanding_selftest_session():
# 	"""pick a session"""
# 		result.enableDuplicateFilter()
# 		for bindings in result:
# 			return run_outstanding_testcases(str(bindings.getValue('session')))






# from rq import get_current_job
# job = get_current_job()








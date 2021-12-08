# todo configure agraph to ignore duplicate triples


def start_a_testing_session():
	# first we assert the metatask into the db
	a = agc()
	bn = a.createBNode()
	selftest = agc.namespace('https://rdf.lodgeit.net.au/v1/selftest#')
	a.add(bn, RDF.TYPE, selftest.Session)
	for p in testcase_permutations():
		a.add(bn, selftest.has_testcase, Tc)



def testcase_permutations():
	return celery_app.signature('invoke_rpc.call_prolog').apply_async([{"method": "testcase_permutations", "params": {}}]).get()[1]



def continue_testing_session():
	"""pick a session"""
	a = agc()
	with a.prepareTupleQuery(query="""
    SELECT DISTINCT ?session WHERE {
        ?session rdf:type selftest:Session .
        FILTER NOT EXISTS {?session selftest:closed true}
    }
    """).evaluate() as result:
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
			return do_testcase(bindings.getValue('testcase'), bindings.getValue('data'))


def do_testcase(testcase, data):
	pass



def process_response(response):
	for report in response['reports']:
		# assert it into the db
		# grab the file
		# do the comparisons
		pass


def reopen_last_testing_session():
	pass

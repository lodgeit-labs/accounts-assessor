from io import StringIO
from xml.etree.ElementTree import canonicalize, fromstring

from luigi.freezing import FrozenOrderedDict
from defusedxml.ElementTree import parse as xmlparse 
import xmldiff
import xmldiff.main, xmldiff.formatting
#from xmldiff import main as xmldiffmain, formatting
import xmldiff
import requests
import datetime
import logging
import shutil
import time
import luigi
import json
import glob
import pathlib
from pathlib import Path as P, PurePath
import sys,os
from urllib.parse import urlparse

from luigi.parameter import _DictParamEncoder
from runner.utils import *

#print(sys.path)
#print(os.path.dirname(__file__))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../../sources/common')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../..')))
from fs_utils import directory_files, find_report_by_key
import fs_utils
from robust_sdk.xml2rdf import Xml2rdf
from common import robust_tests_folder
from json import JSONEncoder


logger = logging.getLogger('robust')

class MyJSONEncoder(JSONEncoder):
	def default(self, o):
		if isinstance(o, PurePath):
			return o.__fspath__()

		if isinstance(o, FrozenOrderedDict):
			return o.get_wrapped()

		return super().default(o)




def json_dump(obj, f):
	json.dump(obj, f, indent=4, sort_keys=True, cls=MyJSONEncoder)



class Dummy(luigi.Task):
	def run(self):
		pass
	def complete(self):
		return False


def symlink(source, target):
	# fixme, gotta get a safe file name in source.parent 
	tmp = source+str(os.getpid()) + "." + str(time.time())
	subprocess.call([
		'/bin/ln', '-s',
		target,
		tmp
	])
	os.rename(tmp, source)




class TestPrepare(luigi.Task):
	test = luigi.parameter.DictParameter()


	def run(self):
		request_files_dir: pathlib.Path = P(self.test['path']) / 'inputs'
		request_files_dir.mkdir(parents=True, exist_ok=True)
		inputs = self.copy_inputs(request_files_dir)
		inputs.append(self.write_job_json(request_files_dir))
		with self.output().open('w') as out:
			json_dump(inputs, out)
		#symlink(P(self.test['path']) / 'testcase', (P(self.test['suite']) / self.test['dir']).absolute())

	def copy_inputs(self, request_files_dir):
		files = []
		input_file: pathlib.Path
		for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('request/*'))):
			x = None
			if str(input_file).endswith('/request.xml'):
				x = Xml2rdf().xml2rdf(input_file, request_files_dir)
			if x is None:
				x = request_files_dir / input_file.name
				shutil.copyfile(input_file, x)
			files.append(x)
		return files


	def write_job_json(self, request_files_dir):
		data = dict(
			custom_job_metadata = dict(self.test),
			worker_options = dict(self.test['worker_options'])
		)
		fn = request_files_dir / 'request.json'
		with open(fn, 'w') as fp:
			json_dump(data, fp)
		return fn


	def write_custom_job_metadata(self, request_files_dir):
		data = dict(self.test)


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'request_files.json')



def make_request(test, request_files):
	url = test['robust_server_url']
	logger.debug('')
	logger.debug('querying ' + url)

	request_format = 'xml' if any([str(i).lower().endswith('xml') for i in request_files]) else 'rdf'

	files = {}
	for idx, input_file in enumerate(request_files):
		files['file' + str(idx+1)] = open(request_files[idx])
	return requests.post(
			url + '/upload',
			params={'request_format':request_format, 'requested_output_format': test['requested_output_format']},
			files=files
	)



class TestStart(luigi.Task):
	"""trigger a job run on the robust server, and save the handle to the job in a file"""

	test = luigi.parameter.DictParameter()
	request_files = luigi.parameter.ListParameter()

	def run(self):
		resp = make_request(self.test, self.request_files)
		if resp.ok:
			handle = find_report_by_key(resp.json()['reports'], 'job_api_url')
			logger.debug('handle: ' + handle)
			with self.output().open('w') as o:
				o.write(handle)
		else:
			resp.raise_for_status()


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'handle')




class TestResultImmediateXml(luigi.Task):
	test = luigi.parameter.DictParameter()

	def requires(self):
		return TestPrepare(self.test)

	def run(self):
		with self.input().open() as request_files_f:
			request_files = json.load(request_files_f)

		resp = make_request(self.test, request_files)
		job = {'status': resp.status_code}

		result_xml = luigi.LocalTarget(P(self.test['path']) / 'outputs' / 'result.xml')
		result_xml.makedirs()

		#if resp.ok:
		with result_xml.temporary_path() as result_xml_fn:
			with open(result_xml_fn, 'w') as result_xml_fd:
				result_xml_fd.write(resp.text)
		job['result'] = 'outputs/result.xml'

		with self.output().temporary_path() as response_fn:
			with open(response_fn, 'w') as response_fd:
				json_dump(job, response_fd)

	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'response.json')



class TestResult(luigi.Task):
	test = luigi.parameter.DictParameter()

	def requires(self):
		return TestPrepare(self.test)

	def run(self):
		with self.input().open() as request_files_f:
			request_files = json.load(request_files_f)

		start = TestStart(self.test, request_files)
		yield start
		with start.output().open() as fd:
			handle = fd.read() 
		with self.output().temporary_path() as tmp:
			while True:
				logger.info('...')
				time.sleep(15)

				job = requests.get(handle).json()
				with open(tmp, 'w') as out:
					json_dump(job, out)

				if job['status'] in [ "Failure", 'Success']:
					break
				elif job['status'] in [ "Started", "Pending"]:
					pass
				else:
					raise Exception('weird status')


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'job.json')




class TestEvaluateImmediateXml(luigi.Task):

	priority = 100
	test = luigi.parameter.DictParameter()

	def requires(self):
		return TestResultImmediateXml(self.test)


	def run(self):

		def done(delta):
			with self.output()['evaluation'].open('w') as out:
				json_dump({'test':dict(self.test), 'job': status, 'delta':delta}, out)

		with open(P(self.input().path)) as fd:
			response = json.load(fd)
		status = response['status']

		with open(os.path.abspath(P(self.test['suite']) / self.test['dir'] / 'response.json')) as fd:
			expected_response = json.load(fd)
		expected_status = expected_response['status']

		if status != expected_status:
			return done([f'status({status}) != expected_status({expected_status})'])

		if status == 200:
			#with open() as fd:

			result_fn = P(self.test['path']) / response['result']
			expected_fn = P(self.test['suite']) / self.test['dir'] / 'responses' / 'response.xml'
			
			canonical_result_xml_string = canonicalize(from_file=result_fn, strip_text=True)
			canonical_expected_xml_string = canonicalize(from_file=expected_fn, strip_text=True)
			
			result = fromstring(canonical_result_xml_string)
			expected = fromstring(canonical_expected_xml_string)
			
			#result = xmlparse(result_fn).getroot()
			#expected = xmlparse(expected_fn).getroot()

			# diff_trees()
			diff = []
			xml_diff = xmldiff.main.diff_files(
				#result_fn, 
				#expected_fn,
				StringIO(canonical_result_xml_string),
				StringIO(canonical_expected_xml_string),
				# formatter=xmldiff.formatting.XMLFormatter(
				# 	normalize=xmldiff.formatting.WS_BOTH,
				# 	pretty_print=True,
				# 	
				# )
			)
			logger.info(canonical_result_xml_string)
			logger.info(canonical_expected_xml_string)
			
			
			logger.info(xml_diff)
			
			# if xml_diff != "":
			# 	diff.append(xml_diff)
			# 	diff.append(xmldiff.main.diff_files(result_fn, expected_fn))
			# 	shortfall = expected.find("./LoanSummary/RepaymentShortfall")
			# 	if shortfall is not None:
			# 		shortfall = shortfall.text
			# 	
			# 	diff.append(dict(
			# 		type='div7a',
			# 		failed=result.tag == 'error',
			# 		expected_shortfall=shortfall
			# 	))
								
			return done(diff)

		return done([])

	def output(self):
		return {
			'evaluation':luigi.LocalTarget(P(self.test['path']) / 'evaluation.json'),
			'outputs':luigi.LocalTarget(P(self.test['path']) / 'outputs')
		}





class TestEvaluate(luigi.Task):
	priority = 100

	test = luigi.parameter.DictParameter()


	def requires(self):
		return TestResult(self.test)


	def run(self):

		# judiciously picked list of interesting differences between expected and actual results
		delta:list[dict] = []

		# job info / response json sent by robust api
		job_fn = P(self.input().path)
		with open(job_fn) as job_fd:
			job = json.load(job_fd)

		def done():
			with self.output()['evaluation'].open('w') as out:
				json_dump({'test':dict(self.test), 'job': job, 'delta':delta}, out)


		# directory where we'll download reports that we want to analyze
		results: luigi.LocalTarget = self.output()['outputs']
		P(results.path).mkdir(parents=True, exist_ok=True)


		job_expected_fn = os.path.abspath(P(self.test['suite']) / self.test['dir'] / 'job.json')
		logging.getLogger('robust').info(job_expected_fn)
		overwrite_job_json_op = {"op": "cp", "src": str(self.input().path), "dst": str(job_expected_fn)}

		try:
			job_expected = json.load(open(job_expected_fn))
		except FileNotFoundError:
			jobfile_missing_delta = {
							"msg":"job.json is missing in testcase",
							"fix": overwrite_job_json_op
						}
			delta.append(jobfile_missing_delta)
			return done()


		# if job['status'] != job_expected['status']:
		# 	delta.append({
		# 		"msg":"job['status'] differs",# + ": " + jsondiffstr(job['status'] != job_expected['status'])
		# 		"fix": [overwrite_job_json_op]
		# 	})
		# 	return done()
		#
		#
		# saved_reports = [{'fn':fn} for fn in glob()]
		#
		#
		# if job['status'] != 'Success':
		# 	if saved_reports != []:
		# 		delta.append({
		# 			"msg":"extraneous saved report files in a testcase that should fail"
		# 		})
		# 		return done()
		#
		#
		#
		# if job_expected['status'] == 'Success':
		# 	reports = job['result']['reports']
		# else:
		# 	reports = []
		#
		#
		#
		# expected_reports = for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('*'))):
		#
		#
		# reports_to_compare = []
		#
		# for r in expected_reports:
		# 	fn = r['fn']
		# 	received_report = find_report_by_key(reports, 'fn', fn)
		# 	if received_report is None:
		# 		delta.append({
		# 			"msg": f"report {fn} is missing in testcase",
		# 			"fix": {"op": "cp", "src": fn, "dst": results.path}
		# 		})
		# 	else:
		# 		reports_to_compare.append({'expected_fn': fn, 'received_url': received_report['url']})
		#
		#
		#
		# reports = []
		# if job['status'] == 'Success':
		# 	result = job['result']
		# 	if type(result) != dict or 'reports' not in result:
		# 		delta.append("""type(result) != dict or 'reports' not in result""")
		# 	else:
		# 		reports = result['reports']
		#
		#
		#
		# 		with results.temporary_path() as tmp:
		# 			alerts_got = json.load(open(fetch_report(tmp, find_report_by_key(reports, 'alerts_json'))))
		#
		# 		alerts_expected = json.load(open(P(self.test['suite']) / 'responses' / 'alerts_json.json'))
		#
		# 		if alerts_expected != alerts_got:
		# 			delta.append("""alerts_expected != alerts_got""")



	def output(self):
		return {
			# this creates some chance for discrepancies to creep in.. "exceptional cases, for example when central locking fails "
			'evaluation':luigi.LocalTarget(P(self.test['path']) / 'evaluation.json'),
			'outputs':luigi.LocalTarget(P(self.test['path']) / 'outputs')
		}



def fetch_report(tmp, url):
	fn = pathlib.Path(urlparse(url).path).name
	out = P(tmp) / fn
	with open(out, 'wb') as result_file:
		shutil.copyfileobj(requests.get(url, stream=True).raw, result_file)
	return out



class Permutations(luigi.Task):
	session = luigi.parameter.PathParameter()
	robust_server_url = luigi.parameter.OptionalParameter(default='http://localhost:80')
	suite = luigi.parameter.OptionalPathParameter(default='../endpoint_tests')
	debug = luigi.parameter.OptionalBoolParameter(default=None, parsing=luigi.BoolParameter.EXPLICIT_PARSING)
	dirglob = luigi.parameter.OptionalParameter(default='')


	def robust_testcase_dirs(self):
		return fs_utils.robust_testcase_dirs(self.suite, self.dirglob)


	def required_evaluations(self):
		for dir in self.robust_testcase_dirs():
			for debug in ([False, True] if self.debug is None else [self.debug]):
				
				requested_output_format = 'immediate_xml' if P(self.suite / dir / 'response.json').exists() else 'job_handle' 

				yield {
					'robust_server_url': self.robust_server_url,
					'requested_output_format': requested_output_format,
					'suite': str(self.suite),
					'dir': str(dir),
					'worker_options': {
						'prolog_debug': debug,
					},
					'path':
						str(
							self.session /
							 dir /
							 ('debug' if debug else 'nodebug')
						)
				}


	def run(self):
		with self.output().open('w') as out:
			json_dump(list(self.required_evaluations()), out)
	def output(self):
		return luigi.LocalTarget(self.session / 'permutations.json')





def optional_session_path_parameter():
	return luigi.parameter.OptionalPathParameter(default=robust_tests_folder() + str(datetime.datetime.utcnow()).replace(' ', '_').replace(':', '_'))




class Summary(luigi.Task):
	session = optional_session_path_parameter()


	def requires(self):
		return Permutations(self.session)


	def make_latest_symlink(self):
		target = self.session.parts[-1]
		symlink = self.session / 'latest'
		ccss(f'ln -s {target} {symlink}')
		ccss(f'mv {symlink} {robust_tests_folder()}')


	def run(self):
		with self.input().open() as pf:
			permutations = json.load(pf)

		evals = []
		for test in permutations:
			match test['requested_output_format']:
				case 'job_handle':
					evals.append(TestEvaluate(test))
				case 'immediate_xml':
					evals.append(TestEvaluateImmediateXml(test))
				case _:
					raise Exception('unexpected request_format')

		self.make_latest_symlink()
		yield evals

		with self.output().open('w') as out:
			summary = []
			for eval in evals:
				with eval.output()['evaluation'].open() as e:
					evaluation = json.load(e)
				summary.append(evaluation)
			json_dump(summary, out)

			#RepaymentShortfall


	def output(self):
		return luigi.LocalTarget(self.session / 'summary.json')




class TestDebugPrepare(luigi.WrapperTask):
	""" a debugging target that only prepares input files, without actually starting any jobs
	"""
	session = optional_session_path_parameter()

	def requires(self):
		return Permutations(self.session)

	def run(self):
		with self.input().open() as pf:
			yield [TestPrepare(t) for t in json.load(pf)]













"""

	`evaluate ledger test result`:
		inputs:
			expected result: a directory 
			actual result: a directory

		run:

			test('response_xml', xml).
			test('general_ledger_json', json).
			test('investment_report_json', json).
			test('investment_report_since_beginning_json', json).
			
			/* ignore these keys: */
			ignore(_, _, all-_, _) :- !. /* a link to the containing directory */
			ignore(_, _, request_xml-_, _) :- !.
			ignore(_, _, 'doc.n3'-_, _) :- !.
			ignore(_, _, 'doc.trig'-_, _) :- !.
			
			
			Url = loc(absolute_url,Report.url),
			fetch_report_file_from_url(Url, Returned_Report_Path),
			tmp_uri_to_saved_response_path(Testcase, Url, Saved_Report_Path),
			Saved_Report_Path = loc(absolute_path, Saved_Report_Path_Value),
			(   \+exists_file(Saved_Report_Path_Value)
				results[possible_actions] += {copy file from..
				or
				testcase_working_directory / 'fixes' / 'replace_{report_key}.sh' <<
					cp xx yy
						 
			
				

			
			if a particular simple testcase fails (with a particular reasoner), we may want to be able to pause all the remaining tasks? or cancel the complex testcases somehow..





| Luigi is designed to work best when each job has one output, so anything you do that requires multiple outputs per job will feel a bit hacky. You can make your job a bit less hacky if all of the outputs go into the same directory. Then your output can be that directory. You don't need to create a file to list the directory contents or override complete in this case.


compare directories: https://dir-content-diff.readthedocs.io/en/latest/



notsure / future:

	(repeated) input immutability checks:
		check that files of endpoint tests did not change during the run
		after all tasks are done, or before?
		in practice, you may often want to tweak a testcase input while a pipeline is running, if you know that you still have time before the testcase is read
		optional consistency check of robust server:
			for all test evaluations:
				robust_server_version is the same




ts = luigi.Parameter(default=datetime.datetime.utcnow().isoformat())




# from luigi.local_target import LocalTarget

# a = LocalTarget('./banana/nanana/na')
# a.makedirs()
"""
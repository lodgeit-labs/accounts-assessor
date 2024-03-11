import urllib
from io import StringIO
from xml import etree
from xml.etree.ElementTree import canonicalize, fromstring, tostring

import psutil
from furl import furl
import lxml.etree

from luigi.freezing import FrozenOrderedDict
from defusedxml.ElementTree import parse as xmlparse
import xmldiff
import xmldiff.main, xmldiff.formatting
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
import sys, os
from urllib.parse import urlparse

# from luigi.parameter import_DictParamEncoder

from runner.compare import my_xml_diff
from runner.utils import *

# print(sys.path)
# print(os.path.dirname(__file__))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../../sources/common/libs/misc')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../../sources/common/libs/sdk/src')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../lib')))
from fs_utils import directory_files, find_report_by_key
from robust_sdk.xml2rdf import Xml2rdf
from common import robust_tests_folder, print_summary_summary
from json import JSONEncoder

aaa = os.environ.get('AUTH').split(':')
aaa = aaa[0], aaa[1]

requests_session = requests.Session()
requests_adapter = requests.adapters.HTTPAdapter(max_retries=5)
requests_session.mount('http://', requests_adapter)
requests_session.mount('https://', requests_adapter)

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


class AssistantStartup(luigi.Task):
	"""just a dummy task to pass to an assitant worker. Could be simplified."""
	ts = luigi.Parameter(default=datetime.datetime.utcnow().isoformat())

	def run(self):
		self.output().open('w').close()

	def output(self):
		return luigi.LocalTarget('/tmp/luigi_dummy/%s' % self.ts)


def symlink(source, target):
	# fixme, gotta get a safe file name in source.parent 
	tmp = source + str(os.getpid()) + "." + str(time.time())
	subprocess.call(['/bin/ln', '-s', target, tmp])
	os.rename(tmp, source)


class TestPrepare(luigi.Task):
	test = luigi.parameter.DictParameter()

	@property
	def testcasedir(self):
		return P(self.test['suite']) / self.test['dir']

	def run(self):
		request_files_dir: pathlib.Path = P(self.test['path']) / 'inputs'
		logger.debug(f'request_files_dir: {request_files_dir}')
		request_files_dir.mkdir(parents=True, exist_ok=True)
		inputs = self.copy_inputs(request_files_dir)

		logger.debug(f'done copying inputs.')
		inputs.append(self.write_job_json(request_files_dir))
		with self.output().open('w') as out:
			json_dump(inputs, out)

	# symlink(P(self.test['path']) / 'testcase', (P(self.test['suite']) / self.test['dir']).absolute())

	def copy_inputs(self, request_files_dir):
		files = []
		input_file: pathlib.Path
		for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('inputs/*'))):
			final_name = None
			if str(input_file).endswith('/request.xml'):
				final_name = Xml2rdf().xml2rdf(input_file, request_files_dir)
			if final_name is None:
				if '/.#' in str(input_file):
					continue
				final_name = request_files_dir / input_file.name
				logger.debug(f'copying {input_file}')
				shutil.copyfile(input_file, final_name)
			files.append(final_name)
		return files


	def write_job_json(self, request_files_dir):
		try:
			with open(self.testcasedir / 'request.json') as fp:
				metadata = json.load(fp)
		except FileNotFoundError:
			metadata = {}
		data = dict(
			**metadata,
			custom_job_metadata = dict(self.test),
			worker_options = dict(self.test['worker_options']),
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
		logger.debug(f'input_file: {input_file}')
		files['file' + str(idx+1)] = open(input_file, 'rb')
	return requests_session.post(
			url + '/upload',
			params={'request_format':request_format, 'requested_output_format': test['requested_output_format']},
			files=files,
			auth=aaa
	)



class TestStart(luigi.Task):
	"""trigger a job run on the robust server, and save the handle to the job in a file"""

	test = luigi.parameter.DictParameter()
	request_files = luigi.parameter.ListParameter()

	@property
	def resources(self):
		for f in self.request_files:
			if f.endswith('/request.json'):
				with open(f) as fd:
					j = json.load(fd)
				nodebug_mem_reserve_mb = j.get('nodebug_mem_reserve_mb', 25)
				o = j.get('worker_options')
				if o is not None:
					if o.get('prolog_debug') is True:
						nodebug_mem_reserve_mb *= 4
		return {'nodebug_mem_reserve_mb': min(1, nodebug_mem_reserve_mb / (psutil.virtual_memory().available / 1000000))}

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

		if resp.ok:
			job['url'] = resp.url
			# get the url of the directory of the file pointed-to by url:
			uuuu = furl(job['url'])
			uuuu.path = '/'.join(str(uuuu.path).split('/')[:-1])
			job['dir'] = uuuu.url

		result_xml = luigi.LocalTarget(P(self.test['path']) / 'results' / 'response.xml')
		result_xml.makedirs()

		# if resp.ok:
		with result_xml.temporary_path() as result_xml_fn:
			with open(result_xml_fn, 'w') as result_xml_fd:
				result_xml_fd.write(resp.text)
		job['result'] = 'results/response.xml'

		with self.output().temporary_path() as response_fn:
			with open(response_fn, 'w') as response_fd:
				json_dump(job, response_fd)

		logger.debug(f'{resp.text=}')

	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'response.json')


class TestEvaluateImmediateXml(luigi.Task):
	priority = 100
	test = luigi.parameter.DictParameter()

	def requires(self):
		return TestResultImmediateXml(self.test)

	def run(self):

		with open(P(self.input().path)) as fd:
			response = json.load(fd)
		status = response['status']

		def done(delta):
			with self.output()['evaluation'].open('w') as out:
				json_dump({'test': dict(self.test), 'job': status, 'delta': delta, 'response': response}, out)

		expected_response_json_fn = (P(self.test['suite']) / self.test['dir'] / 'response.json')
		if expected_response_json_fn.exists():
			expected_response = json_load(expected_response_json_fn)
		else:
			return done([{"msg": f"response.json is missing in testcase", "fix": {"op": "cp", "src": str(self.input().path), "dst": str(expected_response_json_fn)}}])

		expected_status = expected_response['status']

		if status != expected_status:
			return done([f'status({status}) != expected_status({expected_status})'])

		if status == 200:

			result_fn = P(self.test['path']) / response['result']
			expected_fn = P(self.test['suite']) / self.test['dir'] / 'results' / 'response.xml'

			if not expected_fn.exists():
				return done([{"msg": f"response.xml is missing in testcase", "fix": {"op": "cp", "src": str(result_fn), "dst": str(expected_fn)}}])

			canonical_result_xml_string = canonicalize(from_file=result_fn, strip_text=True)
			canonical_expected_xml_string = canonicalize(from_file=expected_fn, strip_text=True)

			result = fromstring(canonical_result_xml_string)
			expected = fromstring(canonical_expected_xml_string)

			logger.debug((result))
			logger.debug((expected))

			return done(list(my_xml_diff(result, expected)))

		return done([])

	def output(self):
		return {'evaluation': luigi.LocalTarget(P(self.test['path']) / 'evaluation.json'), 'results': luigi.LocalTarget(P(self.test['path']) / 'results')}


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

				job = requests_session.get(handle, auth=aaa).json()
				with open(tmp, 'w') as out:
					json_dump(job, out)

				if job['status'] in ["Failure", 'Success']:
					break
				elif job['status'] in ["Started", "Pending"]:
					pass
				else:
					raise Exception('weird status')

	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'job.json')



def cpop(src, dst):
	link = '\e]8;;", Url,"\e\\   ", Title, "   \e]8;;\e\\\n'
	return {"op": "cp", "src": str(src), "dst": str(dst), 'link':link}




class TestEvaluate(luigi.Task):
	priority = 100

	test = luigi.parameter.DictParameter()

	@property
	def testcasedir(self):
		return P(self.test['suite']) / self.test['dir']

	def requires(self):
		return TestResult(self.test)

	def run(self):

		logger.debug(f'')
		logger.debug(f'')
		logger.debug(f'TestEvaluate:')

		# judiciously picked list of interesting differences between expected and actual results.. or just the first difference
		delta: list[dict] = []

		# job json / response json sent by robust api, coming through the TestResult requires()'d above
		job_fn = P(self.input().path)
		with open(job_fn) as job_fd:
			job = json.load(job_fd)

		def done(critical_delta=None):
			if critical_delta is not None:
				delta.append(critical_delta)
			with self.output()['evaluation'].open('w') as out:
				json_dump({'test': dict(self.test), 'job': job, 'delta': delta}, out)

		# get list of saved reports
		testcase_results_dir = self.testcasedir / 'results'
		saved_reports = sorted(filter(lambda x: not (testcase_results_dir / x).is_dir(), glob.glob(root_dir=testcase_results_dir, pathname='*')))
		logger.debug(f'{saved_reports=}')
		logger.debug(f'')

		# directory where we'll download reports that we want to analyze
		results: luigi.LocalTarget = self.output()['results']
		P(results.path).mkdir(parents=True, exist_ok=True)

		#
		# tackle issues with job.json nonexistent or job status differs:
		#

		job_expected_fn = os.path.abspath(P(self.test['suite']) / self.test['dir'] / 'job.json')
		logger.info(f'{job_expected_fn=}')
		logger.debug(f'')
		overwrite_job_json_op = {"op": "cp", "src": str(self.input().path), "dst": str(job_expected_fn)}

		try:
			job_expected = json.load(open(job_expected_fn))
		except FileNotFoundError:
			return done({"msg": "job.json is missing in testcase", "fix": overwrite_job_json_op})

		if job['status'] != job_expected['status']:
			return done({"msg": f"job['status'] differs, {job['status']=} != {job_expected['status']=}", "fix": overwrite_job_json_op})

		job_result = job['result']
		job_result_expected = job_expected['result']

		if job_result.get('alerts') != job_result_expected.get('alerts'):
			delta.append({"msg": f"alerts in job jsons differ, {job_result.get('alerts')=} != {job_result_expected.get('alerts')=}", "fix": overwrite_job_json_op})

		reports = job_result.get('reports')
		expected_reports = job_result_expected.get('reports')

		if not (type(reports) is list and type(expected_reports) is list):
			if reports != expected_reports:
				return done({"msg": f"job['result']['reports'] != job_expected['result']['reports']", "fix": overwrite_job_json_op})

		if len(reports) != len(expected_reports):
			return done({"msg": f"len(reports) != len(expected_reports)", "fix": overwrite_job_json_op})

		if expected_reports and (job_expected['status'] != 'Success'):
			return done({"msg": "extraneous saved report files in a testcase that should fail"})

		# check that job json actually shows the same alerts as alerts json. 
		# (alerts in job json are a convenience for excel).
		alerts_json = json.load(open(fetch_report(results.path, find_report_by_key(job['result']['reports'], 'alerts_json'))))
		if alerts_json != job['result']['alerts']:
			return done({'msg': 'job json alerts differ from alerts json, this should not happen'})

		# if 'alerts_json.json' in expected_reports:
		# 	alerts_expected = json.load(open(self.testcasedir / 'results' / 'alerts_json.json'))
		# 	if alerts_expected != alerts_json:
		# 		delta.append({"msg": f"alerts != alerts_expected: {alerts_json} != {alerts_expected}", "fix": {"op": "cp", "dst": str(self.testcasedir / 'results' / 'alerts_json.json'), "src": P(results.path) / 'alerts_json.json'}})

		for i, report in enumerate(reports):
			expected_report = expected_reports[i]
			if report['key'] != expected_report['key']:
				done({"msg": f"report['key'] != expected_report['key']: {report['key']} != {expected_report['key']}", "fix": overwrite_job_json_op})

			key = report['key']
			if any(key.endswith(x) for x in 'html directory url file'.split()):
				continue

			if key.endswith('json'):
				got_json = json.load(open(fetch_report(results.path, report['url'])))
				expected_json = json.load(open(self.testcasedir / 'results' / expected_report['val']['url'].split('/')[-1]))
				if got_json != expected_json:
					delta.append({"msg": f"got_json != expected_json", "fix": {"op": "cp", "src": str(self.testcasedir / 'results' / expected_report['val']['url'].split('/')[-1]), "dst": results.path}})
			elif key.endswith('xml'):


				# got_xml = xmlparse(fetch_report(results.path, report['url']))
				# expected_xml = xmlparse(self.testcasedir / 'results' / expected_report['val']['url'].split('/')[-1])
				# 
				# 
				# if canonicalize(got_xml) != canonicalize(expected_xml):
				# 	delta.append({"msg": f"canonicalize(got_xml) != canonicalize(expected_xml)", "fix": {"op": "cp", "src": str(self.testcasedir / 'results' / expected_report['val']['url'].split('/')[-1]), "dst": results.path}})

			
				# swipl -s ../../sources/public_lib/lodgeit_solvers/prolog/utils/compare_xml.pl -g 'compare_xml_files("/home/koom/repos/koo5/accounts-assessor/0/accounts-assessor/tests/endpoint_tests/ledger/good/BankDemo2_xlsx-LodgeiT__July4b/results/xbrl_instance.xml","/home/koom/robust_tmp/last_result/000000_xbrl_instance.xml"),halt.'
			
			
				# we have some fixing to do in xbrl instance generator ... item ordering might be a problem.
			

			else:
				raise Exception(f'unsupported report type: {key}')

		return done()

	def output(self):
		return {# this creates some chance for discrepancies to creep in.. "exceptional cases, for example when central locking fails "
			'evaluation': luigi.LocalTarget(P(self.test['path']) / 'evaluation.json'), 'results': luigi.LocalTarget(P(self.test['path']) / 'results')}


def fetch_report(tmp, url):
	if url is None:
		raise Exception('url is None')
	logger.debug(f'{url=}')
	ppp = urlparse(url)
	logger.debug(f'{ppp=}')
	fn = pathlib.Path(ppp.path).name
	# fn = ppp.path.split('/')[-1]
	out = P(tmp) / fn
	if not out.exists():
		with open(out, 'wb') as result_file:
			shutil.copyfileobj(requests_session.get(url, stream=True, auth=aaa).raw, result_file)
	return out


class Permutations(luigi.Task):
	session = luigi.parameter.PathParameter()
	robust_server_url = luigi.parameter.OptionalParameter(default='http://localhost:80')
	suite = luigi.parameter.OptionalPathParameter(default='../endpoint_tests')
	debug = luigi.parameter.OptionalBoolParameter(default=None, parsing=luigi.BoolParameter.EXPLICIT_PARSING)
	dirglob = luigi.parameter.OptionalParameter(default='')

	def robust_testcase_dirs(self):
		return robust_testcase_dirs(self.suite, self.dirglob)

	def required_evaluations(self):
		for dir in self.robust_testcase_dirs():
			for debug in ([False, True] if self.debug is None else [self.debug]):

				requested_output_format = 'job_handle'

				request_json = P(self.suite / dir / 'request.json')
				if request_json.exists():
					request_json = json_load(request_json)
					requested_output_format = request_json.get('requested_output_format', 'job_handle')

				yield {'requested_output_format': requested_output_format, 'robust_server_url': self.robust_server_url, 'suite': str(os.path.abspath((self.suite))), 'dir': str(dir), 'worker_options': {'prolog_debug': debug, 'skip_dev_runner': not debug, 'ROBUST_ENABLE_NICETY_REPORTS': debug,

				}, 'path': str(self.session / dir / ('debug' if debug else 'nodebug'))}

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
					raise Exception(f'unexpected requested_output_format: {test["requested_output_format"].__repr__()}')

		self.make_latest_symlink()
		yield evals

		with self.output().open('w') as out:
			summary = dict(ok=None, total=None, evaluations=[])
			ok = 0
			bad = []
			for eval in evals:
				with eval.output()['evaluation'].open() as e:
					evaluation = json.load(e)
				summary['evaluations'].append(evaluation)
				if evaluation['delta'] == []:
					ok += 1
				else:
					bad.append(evaluation)
			summary['bad'] = bad
			summary['stats'] = dict(bad=len(bad), ok=ok, total=len(evals))
			json_dump(summary, out)

			# im' not sure we can really do this, not sure if the event handler is always called in the same worker.
			self.summary = summary

	def output(self):
		return luigi.LocalTarget(self.session / 'summary.json')


@Summary.event_handler(luigi.Event.SUCCESS)
def celebrate_success(task):
	logger.info('tadaaaa')
	print_summary_summary(task.summary)



class TestDebugPrepare(luigi.WrapperTask):
	""" a debugging target that only prepares input files, without actually starting any jobs
	"""
	session = optional_session_path_parameter()

	def requires(self):
		return Permutations(self.session)

	def run(self):
		with self.input().open() as pf:
			yield [TestPrepare(t) for t in json.load(pf)]


def json_load(fn):
	with open(fn) as f:
		return json.load(f)


def robust_testcase_dirs(suite='.', dirglob=''):
	dirs0 = [pathlib.Path('.')] + [pathlib.Path(x) for x in sorted(glob.glob(root_dir=suite, pathname='**/' + dirglob, recursive=True))]
	# filter out 'responses' dirs
	# dirs1 = list(filter(lambda x: x.name != 'responses', dirs0))
	# fitler out non-leaf dirs
	# dirs2 = list(filter(lambda x: x not in [y.parent for y in dirs1], dirs1))

	for d in dirs0:
		if glob.glob(root_dir=suite, pathname=str(d) + '/inputs/*') != []:
			yield d


# return dirs2
# 
# 	`evaluate ledger test result`:
# 		inputs:
# 			expected result: a directory 
# 			actual result: a directory
# 
# 		run:
# 
# 			test('response_xml', xml).
# 			test('general_ledger_json', json).
# 			test('investment_report_json', json).
# 			test('investment_report_since_beginning_json', json).
# 			
# 			/* ignore these keys: */
# 			ignore(_, _, all-_, _) :- !. /* a link to the containing directory */
# 			ignore(_, _, request_xml-_, _) :- !.
# 			ignore(_, _, 'doc.n3'-_, _) :- !.
# 			ignore(_, _, 'doc.trig'-_, _) :- !.
# 			
# 			
# 			Url = loc(absolute_url,Report.url),
# 			fetch_report_file_from_url(Url, Returned_Report_Path),
# 			tmp_uri_to_saved_response_path(Testcase, Url, Saved_Report_Path),
# 			Saved_Report_Path = loc(absolute_path, Saved_Report_Path_Value),
# 			(   \+exists_file(Saved_Report_Path_Value)
# 				results[possible_actions] += {copy file from..
# 				or
# 				testcase_working_directory / 'fixes' / 'replace_{report_key}.sh' <<
# 					cp xx yy
# 						 
# 			
# 				
# 
# 			
# 			if a particular simple testcase fails (with a particular reasoner), we may want to be able to pause all the remaining tasks? or cancel the complex testcases somehow..
# 
# 

# 
# 
# | Luigi is designed to work best when each job has one output, so anything you do that requires multiple outputs per job will feel a bit hacky. You can make your job a bit less hacky if all of the outputs go into the same directory. Then your output can be that directory. You don't need to create a file to list the directory contents or override complete in this case.
# 
# 
# compare directories: https://dir-content-diff.readthedocs.io/en/latest/
# 
# 
# 
# notsure / future:
# 
# 	(repeated) input immutability checks:
# 		check that files of endpoint tests did not change during the run
# 		after all tasks are done, or before?
# 		in practice, you may often want to tweak a testcase input while a pipeline is running, if you know that you still have time before the testcase is read
# 		optional consistency check of robust server:
# 			for all test evaluations:
# 				robust_server_version is the same
# 
# 
# 
# 
# ts = luigi.Parameter(default=datetime.datetime.utcnow().isoformat())
# 
# 
# 

# from luigi.local_target import LocalTarget

# a = LocalTarget('./banana/nanana/na')
# a.makedirs()

# 
# 	for expected_report in expected_reports:
# 		received_report = find_report_by_key(job['result']['reports'], 'fn', expected_report)
# 		if received_report is None:
# 			delta.append({
# 				"msg": f"report {expected_fn.name} is missing in results",
# 				"fix": {"op": "cp", "src": str(expected_fn), "dst": results.path}
# 			})
# 		else:
# 			reports_to_compare.append({'expected_fn': expected_fn, 'received_url': received_report['url']})
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
# #
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
# 		alerts_expected = json.load(open(P(self.test['suite']) / 'results' / 'alerts_json.json'))
#
# 		if alerts_expected != alerts_got:
# 			delta.append("""alerts_expected != alerts_got""")

import requests
import datetime
import logging
import shutil
import time
import luigi
import json
import glob
import pathlib
from pathlib import Path as P
import sys,os
from urllib.parse import urlparse

#print(sys.path)
#print(os.path.dirname(__file__))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../../sources/common')))
from fs_utils import directory_files, find_report_by_key






class Dummy(luigi.Task):
	def run(self):
		pass
	def complete(self):
		return False







class AsyncComputationStart(luigi.Task):
	test = luigi.parameter.DictParameter()


	def run(self):
		request_files_dir: pathlib.Path = P(self.test['path']) / 'inputs'
		request_files_dir.mkdir(parents=True, exist_ok=True)
		inputs = self.copy_inputs(request_files_dir)
		inputs.append(self.write_custom_job_metadata(request_files_dir))
		self.run_request(inputs)


	def copy_inputs(self, request_files_dir):
		files = []
		input_file: pathlib.Path
		for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('*'))):
			shutil.copyfile(input_file, request_files_dir / input_file.name)
			files.append(request_files_dir / input_file.name)
		return files

	def write_custom_job_metadata(self, request_files_dir):
		data = dict(self.test)
		fn = request_files_dir / 'custom_job_metadata.json'
		with open(fn, 'w') as fp:
			json.dump(data, fp, indent=4)
		return fn



	def run_request(self, inputs: list[pathlib.Path]):
		url = self.test['robust_server_url']
		logging.getLogger('robust').debug('')
		logging.getLogger('robust').debug('querying ' + url)

		request_format = 'xml' if any([str(i).lower().endswith('xml') for i in inputs]) else 'rdf'


		files = {}
		for idx, input_file in enumerate(inputs):
			files['file' + str(idx+1)] = open(inputs[idx])
		resp = requests.post(
				url + '/upload',
				params={'request_format':request_format},
				files=files
		)
		if resp.ok:
			handle = find_report_by_key(resp.json()['reports'], 'job_api_url')
		else:
			resp.raise_for_status()

		with self.output().open('w') as o:
			o.write(handle)


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'handle')




class AsyncComputationResult(luigi.Task):
	test = luigi.parameter.DictParameter()


	def requires(self):
		return AsyncComputationStart(self.test)


	def run(self):
		with self.input().open() as input:
			handle = input.read()
		with self.output().temporary_path() as tmp:
			while True:
				logging.getLogger('robust').info('...')
				time.sleep(15)

				job = requests.get(handle).json()
				with open(tmp, 'w') as out:
					json.dump(job, out, indent=4, sort_keys=True)

				if job['status'] in [ "Failure", 'Success']:
					break
				elif job['status'] in [ "Started", "Pending"]:
					pass
				else:
					raise Exception('weird status')

	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'job.json')




class Evaluation(luigi.Task):
	priority = 100

	test = luigi.parameter.DictParameter()


	def requires(self):
		return AsyncComputationResult(self.test)



	def run(self):

		# judiciously picked list of interesting differences between expected and actual results
		delta:list[dict] = []

		# job info / response json sent by robust api
		job_fn = P(self.input().path)
		job = json.load(open(job_fn))

		def done():
			with self.output()['evaluation'].open('w') as out:
				json.dump({'test':dict(self.test), 'job': job, 'delta':delta}, out, indent=4, sort_keys=True)


		# directory where we'll download reports that we want to analyze
		results: luigi.LocalTarget = self.output()['outputs']
		P(results.path).mkdir(parents=True, exist_ok=True)


		job_expected_fn = P(self.test['suite']) / 'responses' / 'job.json'
		overwrite_job_json_op = {"op": "cp", "src": self.input().path, "dst": job_expected_fn}

		try:
			job_expected = json.load(open(job_expected_fn))
		except FileNotFoundError:
			jobfile_missing_delta = {
							"msg":"job.json is missing in testcase",
							"fix": overwrite_job_json_op
						}
			delta.append(jobfile_missing_delta)
			return done()

		if job['status'] != job_expected['status']:
			delta.append({
				"msg":"job['status'] differs",# + ": " + jsondiffstr(job['status'] != job_expected['status'])
				"fix": [overwrite_job_json_op]
			})
			return done()


		saved_reports = [{'fn':fn} for fn in glob()]


		if job['status'] != 'Success':
			if saved_reports != []:
				delta.append({
					"msg":"extraneous saved report files in a testcase that should fail"
				})
				return done()





		if job_expected['status'] == 'Success':
			reports = job['result']['reports']
		else:
			reports = []




		expected_reports = for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('*'))):


		reports_to_compare = []

		for r in expected_reports:
			fn = r['fn']
			received_report = find_report_by_key(reports, 'fn', fn)
			if received_report is None:
				delta.append({
					"msg": f"report {fn} is missing in testcase",
					"fix": {"op": "cp", "src": fn, "dst": results.path}
				})
			else:
				reports_to_compare.append({'expected_fn': fn, 'received_url': received_report['url']})



		reports = []
		if job['status'] == 'Success':
			result = job['result']
			if type(result) != dict or 'reports' not in result:
				delta.append("""type(result) != dict or 'reports' not in result""")
			else:
				reports = result['reports']



				with results.temporary_path() as tmp:
					alerts_got = json.load(open(fetch_report(tmp, find_report_by_key(reports, 'alerts_json'))))

				alerts_expected = json.load(open(P(self.test['suite']) / 'responses' / 'alerts_json.json'))

				if alerts_expected != alerts_got:
					delta.append("""alerts_expected != alerts_got""")



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
		dirs0 = [P(x) for x in sorted(glob.glob('**/' + self.dirglob, root_dir=self.suite, recursive=True))]
		dirs1 = list(filter(lambda x: x.name != 'responses', dirs0))
		dirs2 = list(filter(lambda x: x not in [y.parent for y in dirs1], dirs1))
		if dirs2 == []:
			return ['.'] # is this supposed to be self.suite instead?
		return dirs2


	def required_evaluations(self):
		for dir in self.robust_testcase_dirs():
			for debug in ([False, True] if self.debug is None else [self.debug]):
				yield {
					'robust_server_url': self.robust_server_url,
					'suite': str(self.suite),
					'dir': str(dir),
					'debug': debug,
					'path':
						str(
							self.session /
							 dir /
							 ('debug' if debug else 'nodebug')
						)
				}


	def run(self):
		with self.output().open('w') as out:
			json.dump(list(self.required_evaluations()), out, indent=4, sort_keys=True)
	def output(self):
		return luigi.LocalTarget(self.session / 'permutations.json')




class EndpointTestsSummary(luigi.Task):
	session = luigi.parameter.OptionalPathParameter(default='/tmp/robust_tests/'+str(datetime.datetime.utcnow()).replace(' ', '_').replace(':', '_'))


	def requires(self):
		return Permutations(self.session)


	def run(self):
		with self.input().open() as pf:
			permutations = json.load(pf)
		evals = list(Evaluation(t) for t in permutations)
		yield evals

		with self.output().open('w') as out:
			summary = []
			for eval in evals:
				with eval.output()['evaluation'].open() as e:
					evaluation = json.load(e)
				summary.append(evaluation)
			json.dump(summary, out, indent=4, sort_keys=True)


	def output(self):
		return luigi.LocalTarget(self.session / 'summary.json')




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
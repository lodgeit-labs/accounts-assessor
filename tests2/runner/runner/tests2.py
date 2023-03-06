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
		inputs = self.copy_inputs()
		self.run_request(inputs)


	def copy_inputs(self):
		request_files_dir: pathlib.Path = P(self.test['path']) / 'inputs'
		request_files_dir.mkdir(parents=True, exist_ok=True)
		files = []
		input_file: pathlib.Path
		for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('*'))):
			shutil.copyfile(input_file, request_files_dir / input_file.name)
			files.append(request_files_dir / input_file.name)
		return files


	def run_request(self, inputs: list[pathlib.Path]):
		url = self.test['robust_server_url']
		logging.getLogger('robust').debug('')
		logging.getLogger('robust').debug('querying ' + url)

		request_format = 'xml' if any([str(i).lower().endswith('xml') for i in inputs]) else 'rdf'

		resp = requests.post(
				url + '/upload',
				params={'request_format':request_format},
				files={'file1':open(inputs[0])}
		)
		if resp.ok:
			handle = find_report_by_key(resp.json()['reports'], 'task_handle')
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
		while True:
			logging.getLogger('robust').info('...')
			time.sleep(1)
			result = requests.get(handle + '/completed/000000_response.json.json')
			if result.ok:
				reports = result.json()['reports']

				o = self.output()
				P(o.path).mkdir(parents=True)

				for report_key in ['alerts_json', 'result']:
					report_url = find_report_by_key(reports, report_key)
					fn = pathlib.Path(urlparse(report_url).path).name
					with open(P(o.path) / fn, 'wb') as result_file:
						shutil.copyfileobj(requests.get(report_url, stream=True).raw, result_file)

				return


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'outputs')




class Evaluation(luigi.Task):
	priority = 100

	test = luigi.parameter.DictParameter()


	def requires(self):
		return AsyncComputationResult(self.test)


	def run(self):
		response = json.load(open(P(self.input().path) / '000000_alerts_json.json'))
		with self.output().open('w') as out:
			json.dump({'test':dict(self.test), 'alerts':response}, out, indent=4, sort_keys=True)


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'evaluation.json')




class Permutations(luigi.Task):
	session = luigi.parameter.PathParameter()
	robust_server_url = luigi.parameter.OptionalParameter(default='http://localhost:80')
	suite = luigi.parameter.OptionalPathParameter(default='../endpoint_tests')
	debug = luigi.parameter.OptionalBoolParameter(default=None, parsing=luigi.BoolParameter.EXPLICIT_PARSING)


	def robust_testcase_dirs(self):
		dirs0 = [P(x) for x in sorted(glob.glob('**/', root_dir=self.suite, recursive=True))]
		dirs1 = list(filter(lambda x: x.name != 'responses', dirs0))
		dirs2 = list(filter(lambda x: x not in [y.parent for y in dirs1], dirs1))
		if dirs2 == []:
			return ['.']
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
	#sanitize_filename(tss.replace(' ', '_'))

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
				with eval.output().open() as e:
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
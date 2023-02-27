import datetime
import logging
import shutil

import luigi
import luigi.contrib.postgres
import pathlib
import json
import glob
from pathlib import Path as P


class Dummy(luigi.Task):
	def run(self):
		pass
	def complete(self):
		return False





class Result(luigi.Task):
	test = luigi.parameter.DictParameter()


	def run(self):
		inputs = self.copy_inputs()
		self.run_request(inputs)


	def copy_inputs(self):
		request_files_dir: pathlib.Path = P(self.test['path']) / 'inputs'
		request_files_dir.mkdir(parents=True)
		files = []
		input_file: pathlib.Path
		for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('*'))):
			shutil.copyfile(input_file, request_files_dir / input_file.name)
			files.append(request_files_dir / input_file.name)
		return files


	def run_request(self, inputs):
		o = self.output()
		print(o)
		logging.getLogger().debug('banana' + str(o))
		P(o.path).mkdir(parents=True)
		with open(P(o.path) / 'result.xml', 'w') as r:
			r.write('rrrr')


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'outputs')




class Evaluation(luigi.Task):
	test = luigi.parameter.DictParameter()


	def requires(self):
		return Result(self.test)


	def run(self):
		response = json.load(P(self.input().path) / 'response.json')
		with self.output().open('w') as out:
			json.dumps({'ok':true}, out)


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'evaluation.json')




class EndpointTestsSummary(luigi.Task):
	session = luigi.parameter.OptionalPathParameter(default='/tmp/robust_tests/'+str(datetime.datetime.utcnow()).replace(' ', '_').replace(':', '_'))
	#sanitize_filename(tss.replace(' ', '_'))

	robust_server_url = luigi.parameter.OptionalParameter(default='http://localhost:8080')


	def requires(self):
		return list(self.required_evaluations())


	def required_evaluations(self):
		suite = pathlib.Path('../endpoint_tests')
		dirs = sorted(glob.glob('*/*/', root_dir=suite))

		for dir in dirs:
			for debug in [False, True]:
				test = {
					'suite': str(suite),
					'dir': str(dir),
					'debug': debug
				}
				test['path'] = str(self.test_path(test))
				yield Evaluation(test)


	def	test_path(self, test):
		return self.session / test['dir'] / ('debug' if test['debug'] else 'nodebug')


	def run(self):
		with self.output().open('w') as out:
			summary = []
			for evaluation_file in self.input():
				evaluation = json.load(evaluation_file)
				summary.append(evaluation)
			json.dumps(summary, out)


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
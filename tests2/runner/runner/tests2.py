import datetime
import shutil

import luigi
import luigi.contrib.postgres
import pathlib
import json



class Dummy(luigi.Task):
	def run(self):
		pass
	def complete(self):
		return False





class Result(luigi.Task):
	sess = luigi.parameter.PathParameter()
	test = luigi.parameter.DictParameter()


	def run(self):
		inputs = self.copy_inputs()
		self.run_request(inputs)


	def copy_inputs(self):
		request_files_dir: pathlib.Path = self.test.path / 'inputs'
		request_files_dir.mkdir()
		files = []
		input_file: pathlib.Path
		for input_file in sorted(filter(lambda x: not x.is_dir(), (test.suite / test.dir).glob('*'))):
			shutil.copyfile(input_file, request_files_dir)
			files.append(request_files_dir / input_file.name)
		return files




	def output(self):
		return luigi.LocalTarget(self.test.path / 'outputs')





class Evaluation(luigi.Task):
	test = luigi.parameter.DictParameter()


	def requires(self):
		return Result(self.test)


	def run(self):
		with self.output().open('w') as out:
			json.load(self.input() /)
				summary += evaluation
			json.dumps(summary, out)


	def output(self):
		return luigi.LocalTarget(test.path / 'evaluation.json')



def	test_path(session, test):
	return session / test.dir / ('debug' if test.debug else 'nodebug')



class EndpointTestsSummary(luigi.Task):
	session = luigi.parameter.OptionalPathParameter(default='/tmp/robust_tests/'+str(datetime.datetime.utcnow()).replace(' ', '_'))
	robust_server_url = luigi.parameter.OptionalParameter(default='http://localhost:8080')


	def requires(self):
		return list(self.required_evaluations())


	def required_evaluations(self):
		suite = pathlib.Path('../endpoint_tests')
		dirs = sorted(filter(lambda x: x.is_dir(), suite.glob('*/*/')))

		for dir in dirs:
			for debug in [False, True]:
				yield Evaluation({
					suite:suite,
					dir:dir,
					path: test_path(self.session, self.test),
					debug: debug
				})


	def run(self):
		with self.output().open('w') as out:
			summary = []
			for evaluation_file in self.input():
				evaluation = json.load(evaluation)
				summary += evaluation
			json.dumps(summary, out)


	def output(self):
		return luigi.LocalTarget(session / 'summary.json')






		
		dependencies
			`list of available endpoint_tests`
			
^&		dynamic dependencies:
			for i in endpoint_tests:
				`testcase result`(i, session)

	
				
	
	
	`list of available endpoint_tests`
		parameters fs_path: Path, default is "./endpoint_tests"?
		
		run():
	        dirs = glob.glob(fs_path / '*/*/')
	        dirs.sort()
	        return dirs
	


	`testcase result`:
		parameters:
			session
		require:
			query endpoint
		run:
			evaluate ledger testcase
		

	`ledger testcase result`:
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
			
			
			testcase_working_directory = ..
			testcase_working_directory / fetched_files
			testcase_working_directory / results.json
			the exact way we store results depends on the framework...
			


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











"""

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

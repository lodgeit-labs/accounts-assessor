# from luigi.local_target import LocalTarget

# a = LocalTarget('./banana/nanana/na')
# a.makedirs()


import datetime
import luigi
import luigi.contrib.postgres


class AssistantStartup(luigi.Task):
	"""just a dummy task to pass to an assitant worker. Could be simplified."""
	ts = luigi.Parameter(default=datetime.datetime.utcnow().isoformat())

	def run(self):
		time.sleep(10)
		self.output().open('w').close()

	def output(self):
		return luigi.LocalTarget('/tmp/luigi_dummy/%s' % self.ts)


class EndpointTestsSummary(luigi.Task):
	x = luigi.parameter.OptionalPathParameter(default=str(datetime.datetime.utcnow()).replace(' ', '_'))

	def run(self):
		print(self.x + str(self.y))

	def output(self):
		return luigi.contrib.postgres.

"""

|             update_id (str): An identifier for this data set

		
		
| Luigi is designed to work best when each job has one output, so anything you do that requires multiple outputs per job will feel a bit hacky. You can make your job a bit less hacky if all of the outputs go into the same directory. Then your output can be that directory. You don't need to create a file to list the directory contents or override complete in this case.

Z




tasks:

	`endpoint tests results`
		parameters
			robust_server_url: str, default is http://localhost:8080
			endpoint_tests_dir: Path, default is "./endpoint_tests"
		
		dependencies
			`list of available endpoint_tests`
			
		dynamic dependencies:
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
















			
			
			
			




notsure / future:

	(repeated) input immutability checks:
		check that files of endpoint tests did not change during the run 
		after all tasks are done, or before?
		in practice, you may often want to tweak a testcase input while a pipeline is running, if you know that you still have time before the testcase is read 
		optional consistency check of robust server:
			for all test evaluations:
				robust_server_version is the same





compare directories: https://dir-content-diff.readthedocs.io/en/latest/

"""



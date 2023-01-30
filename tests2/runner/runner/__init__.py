from luigi.local_target import LocalTarget

a = LocalTarget('./banana/nanana/na')
a.makedirs()








"""

interesting libs related to luigi, rougly ordered from most interesting to least:
	
	
	
	https://github.com/d6t/d6t-python
		https://github.com/d6t/d6t-python/blob/master/blogs/datasci-dags-airflow-meetup.md
		
	
	
	
	https://github.com/boschglobal/luisy
		- active, ci, tests 
	
	https://github.com/pharmbio/sciluigi
	
	
	
	
	
	https://github.com/kyocum/disdat-luigi/tree/master
		* Simplified pipelines -- Users implement two functions per task: requires and run.
		* Enhanced re-execution logic -- Disdat re-runs processing steps when code or data changes.
		* Data versioning/lineage -- Disdat records code and data versions for each output data set.
		* Share data sets -- Users may push and pull data to remote contexts hosted in AWS S3.
		* Auto-docking -- Disdat dockerizes pipelines so that they can run locally or execute on the cloud.

		
	
	https://pypi.org/project/luigi-tools/
		* --rerun parameter that forces a given task to run again
		* remove the output of failed tasks which is likely to be corrupted or incomplete
		...
	
	
	https://github.com/datails/ruig   
	
	
	
	
	
	https://github.com/pollination/queenbee
	
	
	https://github.com/m3dev/gokart
	
	
	https://github.com/madconsulting/datanectar
		* dynamically available API for HTTP based task execution
		* target locations based on project-level code locations     
		* ..
	
	
	
	https://github.com/pwoolvett/waluigi/blob/master/waluigi/tasks.py
	
	
		
	https://github.com/maurosilber/donkeykong/blob/master/donkeykong/scripts/invalidate.py
	
	
	
	https://github.com/miku/gluish
		minor wrapping and subclasses for conventions / automanaging input/output filenames
		utilities for
			dealing with datetimes
			running shell commands inside tasks
			tsv format data
			
			
		
	https://github.com/bopen/mariobros





A lot of these wrappers / extensions seems to involve conventions and automation of input/output file pathing/naming, and making task parameters a part of those names, in order to make artifacts uniquely related to an exact configuration used to run the pipeline. 

I'm not sure i can actually frame our requirements in terms of a "data pipeline", even if there is some resemblance.



tasks:

	`endpoint tests results`
		parameters
			server_url: str, default is http://localhost:8080
			endpoint_tests_dir: Path, default is "./endpoint_tests"
		
		dependencies
			`list of available endpoint_tests`
			
			
		
	
		evaluation:
			for all test evaluations:
				robust_server_version is the same
	
	
	`list of available endpoint_tests`
		parameters fs_path: Path, default is "./endpoint_tests"?
		
		run():
	        dirs = glob.glob(fs_path / '*/*/')
	        dirs.sort()
	







notsure / future:

	(repeated) input immutability checks: 
		after all tasks are done, or before?
		in practice, you may often want to tweak a testcase input while a pipeline is running, if you know that you still have time before the testcase is read 


"""
from luigi.local_target import LocalTarget

a = LocalTarget('./banana/nanana/na')
a.makedirs()








"""

Workflow Orchestration Tools

	meta
		https://assets-global.website-files.com/5e46eb90c58e17cafba804e9/5f8f885195ca2b64eb6d462c_200027%20ON%20UV%20Workflow%20Orchestration%20White%20Paper.pdf
	
	https://docs.prefect.io/
		https://www.datarevenue.com/en-blog/what-we-are-loving-about-prefect
	
	https://temporal.io
		* Asynchronous Activity Completion
	
	https://nifi.apache.org/	
	
	https://aiida.readthedocs.io/projects/aiida-core/en/latest/topics/provenance/index.html
	
	
	
	https://github.com/d6t/d6t-python
		bring airflow-style DAGs to the data science research and development process.
		https://github.com/d6t/d6t-python/blob/master/blogs/datasci-dags-airflow-meetup.md
		
	
	https://nipype.github.io/pydra/
		* Auditing and provenance tracking: Pydra provides a simple JSON-LD-based message passing mechanism to capture the dataflow execution activities as a provenance graph. These messages track inputs and outputs of each task in a dataflow, and the resources consumed by the task.
	
	https://www.digdag.io/
	
	https://substantic.github.io/rain/docs/quickstart.html
	
	https://github.com/insitro/redun
	
	https://github.com/sailthru/stolos
	
	https://www.nextflow.io/
		dataflow dsl ...
		 

interesting libs related to luigi, rougly ordered from most interesting to least:
	
	https://github.com/boschglobal/luisy
		- active, ci, tests 
		* luisy has a smart way of passing parameters between tasks
		* luisy can just download results of pipelines that were already executed by others
		* Decorating your tasks is enough to define your read/write of your tasks
		* Hash functionality automatically detects changes in your code and deletes files that are created by deprecated project versions
		* Testing module allows easy and quick testing of your implemented pipelines and tasks


	https://github.com/pharmbio/sciluigi
		- active, vm, ...
		* Separation of dependency definitions from the tasks themselves, for improved modularity and composability.
		* Inputs and outputs implemented as separate fields, a.k.a. "ports", to allow specifying dependencies between specific input and output-targets rather than just between tasks. This is again to let such details of the network definition reside outside the tasks.
	
	
	https://github.com/riga/law
		* Remote targets with automatic retries and local caching
		* Automatic submission to batch systems from within tasks
		* Environment sandboxing, configurable on task level
	
	
	https://github.com/kyocum/disdat-luigi/tree/master
		* Simplified pipelines -- Users implement two functions per task: requires and run.
		* Enhanced re-execution logic -- Disdat re-runs processing steps when code or data changes.
		* Data versioning/lineage -- Disdat records code and data versions for each output data set.
		* Share data sets -- Users may push and pull data to remote contexts hosted in AWS S3.
		* Auto-docking -- Disdat dockerizes pipelines so that they can run locally or execute on the cloud.

	https://pypi.org/project/funsies/
		* The design of funsies is inspired by git and ccache. All files and variable values are abstracted into a provenance-tracking DAG structure.

		
	https://github.com/gityoav/pyg-cell	
		* saves and persists the data in nicely indexed tables with primary keys decided by user, no more any nasty key = "COUNTRY_US_INDUSTRY_TECH_STOCK_AAPL_OPTION_CALL_EXPIRY_2023M_STRIKE_100_TOO_LONG_TICKER"
		*  allows you to save the actual data either as npy/parquet/pickle files or within mongo/sql dbs as doc-stores.		
	
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
	
	
	https://pypi.org/project/curifactory/
		* Adds a CLI layer on top of your codebase, a single entrypoint for running experiments
		* Automatic caching of intermediate data and lazy loading of stored objects
		* Jupyter notebook output for further exploration of an experiment run
		* Docker container output with copy of codebase, conda environment, full experiment run cache, and jupyter run notebook
		* HTML report output from each run with graphviz-rendered diagram of experiment
		* Easily report plots and values to HTML report
		* Configuration files are python scripts, allowing programmatic definition, parameter composition, and parameter inheritance
		* Output logs from every run
		* Run experiments directly from CLI or other python code, notebooks, etc.
		
	
	https://github.com/WithPrecedent/chrisjen
	
	
	https://github.com/pwoolvett/waluigi/blob/master/waluigi/tasks.py
	
	
		
	https://github.com/maurosilber/donkeykong/blob/master/donkeykong/scripts/invalidate.py
	
	
	
	https://github.com/miku/gluish
		minor wrapping and subclasses for conventions / automanaging input/output filenames
		utilities for
			dealing with datetimes
			running shell commands inside tasks
			tsv format data
			
			
		
	https://github.com/bopen/mariobros


	notes:
		A lot of these wrappers / extensions seems to involve conventions and automation of input/output file pathing/naming, and making task parameters a part of those names, in order to make artifacts uniquely related to an exact configuration used to run the pipeline. 
		
		I'm not sure i can actually frame our requirements in terms of a "data pipeline", even if there is some resemblance.



purely function composition i guess:
	https://github.com/aitechnologies-it/datafun
	https://www.root.cz/clanky/knihovna-polars-vykonnejsi-alternativa-ke-knihovne-pandas-line-vyhodnocovani-operaci/#k15
	https://pypi.org/project/graphtik/
	https://github.com/hazbottles/flonb
	https://pypi.org/project/pydags/
		
		
		







tasks:

	`endpoint tests results`
		parameters
			server_url: str, default is http://localhost:8080
			endpoint_tests_dir: Path, default is "./endpoint_tests"
		
		dependencies
			`list of available endpoint_tests`
			
		dynamic dependencies:
			for i in endpoint_tests:
				`test result`

	
				
	
	
	`list of available endpoint_tests`
		parameters fs_path: Path, default is "./endpoint_tests"?
		
		run():
	        dirs = glob.glob(fs_path / '*/*/')
	        dirs.sort()
	        return dirs
	


	`ledger test result`:
		




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
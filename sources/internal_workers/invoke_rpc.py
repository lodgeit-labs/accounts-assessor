import logging,json, subprocess, os, sys, shutil, shlex

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tmp_dir_path import git, sources, create_tmp_directory_name, create_tmp, get_tmp_directory_absolute_path, ln
from fs_utils import command_nice, flatten_lists



import remoulade



def call_prolog_calculator2(kwargs):
	msg = kwargs['msg']
	# this is where prolog will put reports:
	result_tmp_directory_name, result_tmp_path = create_tmp()
	msg['params']['result_tmp_directory_name'] = result_tmp_directory_name

	# symlink from "final result"(aka "task_handle") directory to actual result directory:
	final_result_tmp_directory_path = None
	if 'final_result_tmp_directory_path' in msg['params']:
		final_result_tmp_directory_path = msg['params']['final_result_tmp_directory_path']
		print("final_result_tmp_directory_path: " + final_result_tmp_directory_path)
		if final_result_tmp_directory_path != None:
			ln('../'+result_tmp_directory_name, final_result_tmp_directory_path + '/' + result_tmp_directory_name)
		# symlink tmp/last_result to tmp/xxxxx:
		last_result_symlink_path = get_tmp_directory_absolute_path('last_result')
		if os.path.exists(last_result_symlink_path):
			subprocess.call(['/bin/rm', last_result_symlink_path])
		ln(
			result_tmp_directory_name,
			last_result_symlink_path)

	# write call info txt:
	with open(os.path.join(result_tmp_path, 'rpc_call_info.txt'), 'w') as info:
		info.write('request:\n')
		info.write(str(msg))
		info.write('\n')

	# copy repo status txt to result dir
	shutil.copyfile(
		os.path.abspath(git('sources/static/git_info.txt')),
		os.path.join(result_tmp_path, 'git_info.txt'))

	msg['params'].update(
		uri_params(result_tmp_directory_name)
	)

	result = call_prolog(**kwargs)
	if result['status'] != 'error':
		print('postprocess_doc...')
		print('todo...')
		#celery_app.signature('internal_workers.postprocess_doc').apply_async(args=(result_tmp_path,))
		print('postprocess_doc..')
		ln('../' + result_tmp_directory_name, final_result_tmp_directory_path + '/completed')

	return result



@remoulade.actor
def call_prolog(
		msg,
		dev_runner_options=[],
		prolog_flags='true',
		debug_loading=None,
		debug=None,
		halt=True,
		pipe_rpc_json_to_swipl_stdin=False
):


	# configuration changeable per-request:
	with open(sources('config/worker_config.json'), 'r') as c:
		config = json.load(c)

	# not sure if these should even default to the values in the config json, seems to be more confusing than useful.
	# this one is a command-line parameter
	if debug == None:
		debug = config.get('DEBUG', False)
	dont_gtrace = os.getenv('DONT_GTRACE', config.get('DONT_GTRACE', False))
	die_on_error = os.getenv('DIE_ON_ERROR', config.get('DIE_ON_ERROR', False))

	logging.getLogger().info('msg:')
	logging.getLogger().info(msg)
	sys.stdout.flush()
	sys.stderr.flush()

	#logging.getLogger().warn(os.getcwd())
	#logging.getLogger().warn(os.path.abspath(git('sources/static/git_info.txt')))
	#logging.getLogger().warn(git('sources/static/git_info.txt'))
	#logging.getLogger().warn(os.path.join(result_tmp_path))

	# construct the command line:
	if debug_loading:
		entry_file = 'lib/debug_loading_rpc_server.pl'
	else:
		entry_file = "lib/rpc_server.pl"
	if debug:
		dev_runner_debug_args = [['--debug', 'true']]
		debug_goal = 'debug,set_prolog_flag(debug,true),'
	else:
		dev_runner_debug_args = [['--debug', 'false']]
		debug_goal = 'set_prolog_flag(debug,false),'
	if dont_gtrace:
		debug_goal += 'set_prolog_flag(gtrace,false),'
	else:
		debug_goal += 'guitracer,'
	if die_on_error:
		debug_goal += 'set_prolog_flag(die_on_error,true),'
	if halt:
		halt_goal = ',halt'
	else:
		halt_goal = ''


	input = json.dumps(msg)
	cmd0 = [
		git("sources/public_lib/lodgeit_solvers/tools/dev_runner/dev_runner.pl"),
		['--problem_lines_whitelist',
		 git("sources/public_lib/lodgeit_solvers/tools/dev_runner/problem_lines_whitelist")],
		#['--toplevel', 'false'],
		#['--compile', 'true'],
	]
	cmd0b = dev_runner_debug_args + [["--script", sources(entry_file)]]
	cmd1 = dev_runner_options


	# pipe the command or pass as an argument?
	if pipe_rpc_json_to_swipl_stdin:
		goal = ',utils:print_debugging_checklist,lib:process_request_rpc_cmdline'
	else:
		goal = ",make,utils:print_debugging_checklist,lib:process_request_rpc_cmdline_json_text('" + (input).replace('"','\\"') + "')"



	cmd2 = [['-g', debug_goal + prolog_flags + goal + halt_goal]]
	cmd = cmd0 + cmd0b + cmd1 + cmd2


	cmd = flatten_lists([#'/usr/bin/time',
	#					'-v',
	#					'--f', "user time :%U secs, max mem: %M kb",
						cmd])
	logging.getLogger().warn('invoke_rpc: cmd:')
	logging.getLogger().warn(shlex.join(cmd))


	if pipe_rpc_json_to_swipl_stdin:
		p = subprocess.Popen(cmd, universal_newlines=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)#, shell=True)
		print('invoke_rpc: piping to swipl:')
		print(input)
		sys.stdout.flush()
		(stdout_data, stderr_data) = p.communicate(input = input)# + '\n\n')
	else:
		print('invoke_rpc: invoking swipl...')
		p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE)
		(stdout_data, stderr_data) = p.communicate()


	if stdout_data in [b'', '']:
		return {'status':'error', 'message': 'invoke_rpc: got no stdout from swipl.'}
	else:
		print()
		print("invoke_rpc: prolog stdout:")
		print(stdout_data)
		print("invoke_rpc: end of prolog stdout.")
		print()
		try:
			rrr = json.loads(stdout_data)
			return rrr
		except json.decoder.JSONDecodeError as e:
			print('invoke_rpc:', e)
			print()
			return {'status':'error', 'message': f'invoke_rpc: {e}'}



remoulade.declare_actors([call_prolog])



def uri_params(tmp_directory_name):
	# comment(RDF_EXPLORER_1_BASE, comment, 'base of uris to show to user in generated html')
	rdf_explorer_base = 'http://dev-node.uksouth.cloudapp.azure.com:10036/#/repositories/a/node/'
	rdf_explorer_base = 'http://localhost:10055/#/repositories/a/node/'
	#rdf_namespace_base = 'http://dev-node.uksouth.cloudapp.azure.com/rdf/'
	rdf_namespace_base = 'https://rdf.tmp/'
	request_uri = rdf_namespace_base + 'requests/' + tmp_directory_name
	return {
		"request_uri": request_uri,
		"rdf_namespace_base": rdf_namespace_base,
		"rdf_explorer_bases": [rdf_explorer_base]
	}



# if you want to see current env:
#import sys
#print(sys.path)
#p = subprocess.Popen(['bash', '-c', 'export'], universal_newlines=True)
#p.communicate()



"""
some design/requirements/assumptions about the tasks/rpc framework (the python side):

"""


			#todo: for browser clients: something like return render(request, 'task_taking_too_long.html', {'final_result_tmp_directory_name': final_result_tmp_directory_name})

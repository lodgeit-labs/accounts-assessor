import json, subprocess, os
import internal_workers
import sys, os
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tmp_dir_path import git, sources, create_tmp_directory_name, create_tmp, get_tmp_directory_absolute_path
from celery_module import app
from fs_utils import command_nice, flatten_lists
import logging, json


@app.task
def call_prolog(
		msg,
		final_result_tmp_directory_name=None,
		dev_runner_options=[],
		prolog_flags='true',
		debug_loading=None,
		debug=None,
		halt=True,
		print_cmd_to_swipl_stdin=False
):
	with open(sources('config/worker_config.json'), 'r') as c:
		config = json.load(c)
	# if defined, overrides dev_runner --debug value
	debug = config.get('DEBUG_OVERRIDE', debug)

	msg['params']['result_tmp_directory_name'], result_tmp_path = create_tmp()

	if final_result_tmp_directory_name != None:
		subprocess.call(['/bin/ln', '-s', result_tmp_path, final_result_tmp_directory_name + '/'])

	last_result_symlink_path = get_tmp_directory_absolute_path('last_result')
	if os.path.exists(last_result_symlink_path):
		subprocess.call(['/bin/rm', last_result_symlink_path])
	subprocess.call(['/bin/ln', '-s', result_tmp_path, last_result_symlink_path])

	with open(os.path.join(result_tmp_path, 'rpc_call_info.txt'), 'w') as info:
		info.write('request:\n')
		info.write(str(msg))
		info.write('\n')

	msg['params'].update(
		uri_params(msg['params']["result_tmp_directory_name"])
	)

	# working directory. Should not matter for the prolog app, since everything in the prolog app uses (or should use) lib/search_paths.pl,
	# and dev_runner uses tmp_file_stream.
	os.chdir(git("server_root"))

	# construct the command line

	if debug_loading:
		entry_file = 'lib/debug_loading_rpc_server.pl'
	else:
		entry_file = "lib/rpc_server.pl"
	if debug:
		dev_runner_debug_args = [['--debug', 'true']]
		debug_goal = 'debug,'
	else:
		dev_runner_debug_args = [['--debug', 'false']]
		debug_goal = ''
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

	# the idea is that eventually, we'll only connect to a standalone swipl server from here
	if print_cmd_to_swipl_stdin:
		goal = ',lib:process_request_rpc_cmdline'
	else:
		goal = ",lib:process_request_rpc_cmdline_json_text('" + (input).replace('"','\\"') + "')"

	cmd2 = [['-g', debug_goal + prolog_flags + goal + halt_goal]]
	cmd = cmd0 + cmd0b + cmd1 + cmd2

	logging.getLogger().debug('invoke_rpc: running:')
	# print(shlex.join(cmd)) # python 3.8
	logging.getLogger().debug(command_nice(cmd))
	cmd = flatten_lists(cmd)
	#print(cmd)

	try:
		if print_cmd_to_swipl_stdin:
			p = subprocess.Popen(cmd, universal_newlines=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)#, shell=True)
			logging.getLogger().debug(print('invoke_rpc: piping to swipl:'))
			logging.getLogger().debug(print(input))
			(stdout_data, stderr_data) = p.communicate(input = input)# + '\n\n')
		else:
			p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE)
			(stdout_data, stderr_data) = p.communicate()
	except FileNotFoundError as e:
		print(
			"invoke_rpc: if system PATH is messed up, maybe you're running the server from venv, and activating the venv a second time, from run_common0.sh, messes it up")
		raise

	if stdout_data != b'':
		print()
		print("invoke_rpc: prolog stdout:")
		print(stdout_data)
		print("invoke_rpc: end of prolog stdout.")
		print()
		try:
			rrr = json.loads(stdout_data)
			internal_workers.postprocess_doc.apply_async((result_tmp_path,))
			return msg['params']['result_tmp_directory_name'], rrr
		except json.decoder.JSONDecodeError as e:
			print('invoke_rpc:', e)
			print()
	else:
		print('invoke_rpc: got no stdout from swipl.')
	return msg['params']['result_tmp_directory_name'], {'status':'error'}




def uri_params(tmp_directory_name):
	# comment(RDF_EXPLORER_1_BASE, comment, 'base of uris to show to user in generated html')
	rdf_explorer_base = 'http://dev-node.uksouth.cloudapp.azure.com:10036/#/repositories/a/node/'
	rdf_namespace_base = 'http://dev-node.uksouth.cloudapp.azure.com/rdf/'
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

import threading, json,  subprocess, shutil, ntpath, os, sys
import internal_workers
from tmp_dir_path import *


def call_prolog(msg, final_result_tmp_directory_name, dev_runner_options=[], prolog_flags='true', debug_loading=None, debug=None, halt=True):

	msg['params']['result_tmp_directory_name'], result_tmp_path = create_tmp()
	subprocess.call(['/bin/rm', get_tmp_directory_absolute_path('last_response')])
	subprocess.call(['/bin/ln', '-s', result_tmp_path, get_tmp_directory_absolute_path('last_result')])
	#with open(os.path.join(result_tmp_path, 'info.txt'), 'w') as info:
	#	info.write('request:\n')
	#	info.write(str(msg))
	#	info.write('\n')

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
		dev_runner_debug_args = ['-dtrue']
		debug_goal = 'debug,'
	else:
		dev_runner_debug_args = ['-dfalse']
		debug_goal = ''
	if halt:
		halt_goal = ',halt'
	else:
		halt_goal = ''


	input = json.dumps(msg)

	cmd0 = ['swipl', '-s', git("public_lib/lodgeit_solvers/tools/dev_runner/dev_runner.pl"),'--problem_lines_whitelist',git("public_lib/lodgeit_solvers/tools/dev_runner/problem_lines_whitelist")] + dev_runner_debug_args + ["-s", git(entry_file)]
	cmd1 = dev_runner_options

	# the idea is that eventually, we'll only connect to a standalone swipl server from here
	print_cmd_to_swipl_stdin = False
	if print_cmd_to_swipl_stdin:
		goal = ',lib:process_request_rpc_cmdline'
	else:
		goal = ",lib:process_request_rpc_cmdline_json_text('" + (input).replace('"','\\"') + "')"

	cmd2 = ['-g', debug_goal + prolog_flags + goal + halt_goal]
	cmd = cmd0 + cmd1 + cmd2
	print(' '.join(cmd))

	# show the message that we send
	if print_cmd_to_swipl_stdin:
		print('<<', input)

	try:
		if print_cmd_to_swipl_stdin:
			p = subprocess.Popen(cmd, universal_newlines=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
			(stdout_data, stderr_data) = p.communicate(input = input)
		else:
			p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE)
			(stdout_data, stderr_data) = p.communicate()
	except FileNotFoundError as e:
		print(
			"if system PATH is messed up, maybe you're running the server from venv, and activating the venv second time, from run_common0.sh, messes it up")
		raise

	print("result from prolog:")
	print(stdout_data)
	print("end of result from prolog.")
	try:
		rrr = json.loads(stdout_data)
		internal_workers.postprocess_doc.apply_async((tmp_path,))
		return msg['params']['result_tmp_directory_name'], rrr
	except json.decoder.JSONDecodeError as e:
		print(e)
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


def make_final_result_tmp_directory():
	return create_tmp()


# if you want to see current env:
#import sys
#print(sys.path)
#p = subprocess.Popen(['bash', '-c', 'export'], universal_newlines=True)
#p.communicate()



"""
some design/requirements/assumptions about the tasks/rpc framework (the python side):

"""

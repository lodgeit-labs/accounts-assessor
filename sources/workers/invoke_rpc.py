import logging,json, subprocess, os, sys, shutil, shlex
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tmp_dir_path import git, sources, create_tmp_directory_name, create_tmp, get_tmp_directory_absolute_path, ln
from fs_utils import command_nice, flatten_lists
from tasking import remoulade
from remoulade.middleware import CurrentMessage
from pathlib import Path
from misc import uri_params, env_string



def call_prolog_calculator(**kwargs):
	msg = kwargs['msg']
	params = msg['params']

	if len(params['request_files']) == 1 and params['request_files'][0].lower().endswith('.xml'):
		params['request_format']='xml'
	else:
		params['request_format']='rdf'


	# this is where prolog will put reports:
	result_tmp_directory_name, result_tmp_path = create_tmp()
	params['result_tmp_directory_name'] = result_tmp_directory_name

	params['final_result_tmp_directory_name'] = CurrentMessage.get_current_message().message_id
	if params['final_result_tmp_directory_name'] is None:
		params['final_result_tmp_directory_name'] = 'cli'
	params['final_result_tmp_directory_path'] = get_tmp_directory_absolute_path(params['final_result_tmp_directory_name'])
	Path(params['final_result_tmp_directory_path']).mkdir(parents = True, exist_ok = True)

	print("final_result_tmp_directory_path: " + params['final_result_tmp_directory_path'])

	# link the result dir from the final_result(job_handle) dir
	ln('../'+result_tmp_directory_name, params['final_result_tmp_directory_path'] + '/' + result_tmp_directory_name)

	# symlink tmp/last_result to tmp/xxxxx:
	last_result_symlink_path = get_tmp_directory_absolute_path('last_result')
	try:
		if os.path.exists(last_result_symlink_path):
			subprocess.call(['/bin/rm', last_result_symlink_path])
		ln(
			result_tmp_directory_name,
			last_result_symlink_path)
	except Exception as e:
		print(e)

	# copy repo status txt to result dir
	shutil.copyfile(
		os.path.abspath(git('sources/static/git_info.txt')),
		os.path.join(result_tmp_path, 'git_info.txt'))

	msg['params'].update(
		uri_params(result_tmp_directory_name)
	)

	result = call_prolog(**kwargs)

	# if result['status'] != 'error':
	# 	print('postprocess_doc...')
	# 	print('todo...')
	# 	#celery_app.signature('internal_workers.postprocess_doc').apply_async(args=(result_tmp_path,))
	# 	print('postprocess_doc..')

	ln('../' + result_tmp_directory_name, params['final_result_tmp_directory_path'] + '/completed')

	return result



def call_prolog(
		msg,
		options = None
):
	if options is None:
		options = {}

	result_tmp_path = get_tmp_directory_absolute_path(msg['params']['result_tmp_directory_name']) if 'result_tmp_directory_name' in msg['params'] else None

	default_options = dict(
		dev_runner_options=[],
		prolog_flags='true',
		debug_loading=None,
		prolog_debug=True,
		halt=True,
		pipe_rpc_json_to_swipl_stdin=False,
		dry_run=False,
		MPROF_OUTPUT_PATH=result_tmp_path + '/mem_prof.txt' if result_tmp_path else None,
	)

	with open(sources('config/worker_config.json'), 'r') as c:
		config = json.load(c)

	options = default_options | config | options

	logging.getLogger().info('options: ' + str(options))
	logging.getLogger().info('msg: ' + str(msg))

	sys.stdout.flush()
	sys.stderr.flush()

	# write call info txt:

	ROBUST_CALL_INFO_TXT_PATH = result_tmp_path+'/rpc_call_info.txt' if result_tmp_path else '/tmp/robust_rpc_call_info.txt'
	with open(ROBUST_CALL_INFO_TXT_PATH, 'w') as info_fd:
		info_fd.write('options:\n')
		info_fd.write(json.dumps(options, indent=4))
		info_fd.write('\nrequest:\n')
		info_fd.write(json.dumps(msg, indent=4))
		info_fd.write('\n')


	# construct the command line

	if options['debug_loading']:
		entry_file = 'lib/debug_loading_rpc_server.pl'
	else:
		entry_file = "lib/rpc_server.pl"

	if options['prolog_debug']:
		dev_runner_debug_args = [['--debug', 'true']]
		debug_goal = 'debug,set_prolog_flag(debug,true),'
	else:
		dev_runner_debug_args = [['--debug', 'false']]
		debug_goal = 'set_prolog_flag(debug,false),'

	if options['halt']:
		halt_goal = ',halt'
	else:
		halt_goal = ''


	input = json.dumps(msg)

	#goal = ",make,utils:print_debugging_checklist,lib:process_request_rpc_cmdline_json_text('" + (input).replace('"','\\"') + "')"
	goal = ",utils:print_debugging_checklist,lib:process_request_rpc_cmdline_json_text('" + (input).replace('"','\\"') + "')"
	cmd = flatten_lists([
		#'/usr/bin/time',
		#	'-v',
		#	--f', "user time :%U secs, max mem: %M kb",
		git("sources/public_lib/lodgeit_solvers/tools/dev_runner/dev_runner.pl"),
		['--problem_lines_whitelist',
		 git("sources/public_lib/lodgeit_solvers/tools/dev_runner/problem_lines_whitelist")],
		dev_runner_debug_args + [["--script", sources(entry_file)]],
		options['dev_runner_options'],
		'-g',
		debug_goal + options['prolog_flags'] + goal + halt_goal
	])


	logging.getLogger().warn('invoke_rpc: cmd:')
	env = os.environ.copy() | dict([(k,str(v)) for k,v in options.items()])
	logging.getLogger().warn('env: ' + env_string(env))
	logging.getLogger().warn('cmd: ' + shlex.join(cmd))


	if not options['dry_run']:
		#print('invoke_rpc: invoking swipl...')
		p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE, env=env)
		(stdout_data, stderr_data) = p.communicate()
	else:
		return {'result':'ok'}


	if stdout_data in [b'', '']:
		ret = {'status':'error', 'message': 'invoke_rpc: got no stdout from swipl.'}
		logging.getLogger().warn(str(ret))
		return ret
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




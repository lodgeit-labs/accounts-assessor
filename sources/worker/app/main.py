
app = FastAPI(
	title="Robust worker private api"
)

client_id = subprocess.check_output(['hostname'], text=True).strip() + '-' + str(os.getpid())
def manager_proxy_thread():
	while True:
		r = requests.post(os.environ['MANAGER_URL'] + '/messages', json=dict(id=client_id, procs=['call_prolog', 'arelle', 'download']))
		r.raise_for_status()
		msg = r.json()

		if msg['type'] == 'job':
			if msg['proc'] == 'call_prolog':
				return call_prolog(msg['msg'], msg['worker_options'])
			elif msg['proc'] == 'arelle':
				return arelle(msg['msg'], msg['worker_options'])
#			elif msg['proc'] == 'download':
#				return download(msg['msg'], msg['worker_options'])
#				safely covered by download_bastion i think
			else:
				raise Exception('unknown proc: ' + msg['proc'])



import logging,json, subprocess, os, sys, shutil, shlex
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common/libs/misc')))
from tmp_dir_path import git, sources, create_tmp_for_user, get_tmp_directory_absolute_path, ln
from fs_utils import command_nice, flatten_lists
from tasking import remoulade
from remoulade.middleware import CurrentMessage
from pathlib import Path
from misc import uri_params, env_string




def call_prolog_calculator(params, worker_options):
	
	# just some easy preparation we can do on the worker:
	params |= uri_params(result_tmp_directory_name) | dict(request_format=guess_request_format_rdf_or_xml(params))	
		
	msg = dict(method='calculator', params=params) 
	return call_prolog(msg, worker_options)
	


def call_prolog(
		msg,
		worker_options = None
):
	result_tmp_path = get_tmp_directory_absolute_path(msg['params']['result_tmp_directory_name']) if 'result_tmp_directory_name' in msg['params'] else None


	if worker_options is None:
		worker_options = {}

	with open(sources('config/worker_config.json'), 'r') as c:
		config = json.load(c)

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

	worker_options = default_options | config | worker_options

	
	logging.getLogger().info('worker_options: ' + str(worker_options))
	logging.getLogger().info('msg: ' + str(msg))

	sys.stdout.flush()
	sys.stderr.flush()


	# write call info txt:
	ROBUST_CALL_INFO_TXT_PATH = result_tmp_path+'/rpc_call_info.txt' if result_tmp_path else '/tmp/robust_rpc_call_info.txt'
	with open(ROBUST_CALL_INFO_TXT_PATH, 'w') as info_fd:
		info_fd.write('options:\n')
		info_fd.write(json.dumps(worker_options, indent=4))
		info_fd.write('\nrequest:\n')
		info_fd.write(json.dumps(msg, indent=4))
		info_fd.write('\n')


	# construct the command line

	if worker_options['debug_loading']:
		entry_file = 'lib/debug_loading_rpc_server.pl'
	else:
		entry_file = "lib/rpc_server.pl"

	if worker_options['prolog_debug']:
		dev_runner_debug_args = [['--debug', 'true']]
		debug_goal = 'debug,set_prolog_flag(debug,true),'
	else:
		dev_runner_debug_args = [['--debug', 'false']]
		debug_goal = 'set_prolog_flag(debug,false),'

	if worker_options['halt']:
		halt_goal = ',halt'
	else:
		halt_goal = ''


	input = json.dumps(msg)

	#goal = ",make,utils:print_debugging_checklist,lib:process_request_rpc_cmdline_json_text('" + (input).replace('"','\\"') + "')"
	goal = ",utils:print_debugging_checklist,lib:process_request_rpc_cmdline_json_text('" + (input).replace('"','\\"') + "')"

	goal_opts = ['-g', debug_goal + worker_options['prolog_flags'] + goal + halt_goal]
	
	if worker_options.get('skip_dev_runner', False):
		cmd = flatten_lists(['swipl', '-s', sources(entry_file), goal_opts])
	else:
		cmd = flatten_lists([
			#'/usr/bin/time',
			#	'-v',
			#	--f', "user time :%U secs, max mem: %M kb",
			git("sources/public_lib/lodgeit_solvers/tools/dev_runner/dev_runner.pl"),
			['--problem_lines_whitelist',
			 git("sources/public_lib/lodgeit_solvers/tools/dev_runner/problem_lines_whitelist")],
			dev_runner_debug_args + [["--script", sources(entry_file)]],
			worker_options['dev_runner_options'],
			goal_opts
		])


	logging.getLogger().warn('invoke_rpc: cmd:')
	env = os.environ.copy() | dict([(k,str(v)) for k,v in worker_options.items()])
	logging.getLogger().warn('env: ' + env_string(env))
	logging.getLogger().warn('cmd: ' + shlex.join(cmd))


	if not worker_options['dry_run']:
		#print('invoke_rpc: invoking swipl...')
		p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE, env=env)
		(stdout_data, stderr_data) = p.communicate()
	else:
		return {'result':'ok'}


	if stdout_data in [b'', '']:
		ret = {'alerts':['invoke_rpc: got no stdout from swipl.']}
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




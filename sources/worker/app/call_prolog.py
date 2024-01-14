import logging,json, subprocess, os, sys, shutil, shlex
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common/libs/misc')))
from tmp_dir_path import git, sources, get_tmp_directory_absolute_path, ln
from fs_utils import command_nice, flatten_lists
from pathlib import Path
from app.misc import uri_params, env_string



def call_prolog_calculator(params, worker_options):

	# just some easy preparation we can do on the worker:
	params |= uri_params(result_tmp_directory_name) | dict(request_format=guess_request_format_rdf_or_xml(params))

	msg = dict(method='calculator', params=params)
	return call_prolog(msg, worker_options)



def call_prolog(
		msg,
		worker_options = None
):
	"""
	We have two main ways of invoking prolog:
	1. "RPC" - we send a json request to a server, and get a json response back - or at least it could be a server. 
	In practice, the overhead of launching swipl (twice when debugging) is minimal, so we just launch it for each request.
	( - a proper tcp (http?) server plumbing for our RPC was never written or needed yet).
	
	There are also two ways to pass the goal to swipl, either it's passed on the command line, or it's sent to stdin.
	The stdin method causes problems when the toplevel breaks on an exception, so it's not used, but a bit of the code
	might get reused now, because we will again be generating a goal string that can be copy&pasted into swipl..
	"""

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





# def run_last_request_outside_of_docker(self):
# 	"""
# 	you should run this script from server_root/
# 	you should also have `services` running on the host (it doesnt matter that it's simultaneously running in docker), because they have to access files by the paths that `workers` sends them.
# 	"""
# 	tmp_volume_data_path = '/var/lib/docker/volumes/robust_tmp/_data/'
# 	os.system('sudo chmod -R o+rX '+shlex.quote(tmp_volume_data_path))
# 	last_request_host_path = tmp_volume_data_path + os.path.split(os.readlink(tmp_volume_data_path+'last_request'))[-1]
# 	local_calculator(last_request_host_path)
# 
# 
# """
# >> #PP='' DISPLAY='' RABBITMQ_URL='localhost:5672' REDIS_HOST='redis://localhost' AGRAPH_HOST='localhost' AGRAPH_PORT='10035' REMOULADE_PG_URI='postgresql://remoulade@localhost:5433/remoulade' REMOULADE_API='http://localhost:5005' SERVICES_URL='http://localhost:17788' CSHARP_SERVICES_URL='http://localhost:17789' FLASK_DEBUG='0' FLASK_ENV='production' WATCHMEDO='' ./run_last_request_in_docker_with_host_fs.py --dry_run True --request /app/server_root/tmp/1691798911.3167622.57.1.A52CC96x3070
# """

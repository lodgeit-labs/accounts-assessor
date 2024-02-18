import logging,json, subprocess, os, sys, shutil, shlex
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common/libs/misc')))
from tmp_dir_path import git, sources, get_tmp_directory_absolute_path, ln
from fs_utils import command_nice, flatten_lists
from pathlib import Path
from app.misc import uri_params, env_string




log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.debug('debug call_prolog.py')




def files_in_dir_recursive(worker_tmp_path):
	return [f for f in flatten_lists([list(Path(worker_tmp_path).rglob('*'))]) if f.is_file()]


def call_prolog(
		msg, # {method: calculator or rpc, params:...}
		worker_tmp_directory_name = 'rpc',
		worker_options = None,
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

	worker_tmp_path = get_tmp_directory_absolute_path(worker_tmp_directory_name)
	os.makedirs(worker_tmp_path, exist_ok=True)
	
	if msg.get('method') == 'calculator':
		msg['params'] |= uri_params(msg['params']['result_tmp_directory_name']) | dict(request_format=guess_request_format_rdf_or_xml(msg['params']))

	if worker_options is None:
		worker_options = {}

	try:
		with open(sources('config/worker_config.json'), 'r') as c:
			config = json.load(c)
	except FileNotFoundError:
		config = {}

	default_options = dict(	
		ENABLE_CONTEXT_TRACE_TRAIL=False,
		DISABLE_GRACEFUL_RESUME_ON_UNEXPECTED_ERROR=False,
		GTRACE_ON_OWN_EXCEPTIONS=False,
		ROBUST_ENABLE_NICETY_REPORTS=False,
		skip_dev_runner=True,
		dev_runner_options=[],
		prolog_flags='true',
		debug_loading=None,
		prolog_debug=False,
		halt=True,
		pipe_rpc_json_to_swipl_stdin=False,
		dry_run=False,
		MPROF_OUTPUT_PATH=worker_tmp_path + '/mem_prof.txt'
	)

	worker_options = default_options | config | worker_options


	logging.getLogger().info('worker_options: ' + str(worker_options))
	logging.getLogger().info('msg: ' + str(msg))

	sys.stdout.flush()
	sys.stderr.flush()


	# write call info txt:
	ROBUST_CALL_INFO_TXT_PATH = worker_tmp_path+'/rpc_call_info.txt'
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


	log.debug('invoke_rpc: cmd:')
	env = os.environ.copy() | dict([(k,str(v)) for k,v in worker_options.items()])
	log.debug('env: ' + env_string(env))
	log.debug('cmd: ' + shlex.join(cmd))


	if not worker_options['dry_run']:
		#print('invoke_rpc: invoking swipl...')
		p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE, env=env)
		(stdout_data, stderr_data) = p.communicate()
	else:
		return {'result':'ok'}, []


	if stdout_data in [b'', '']:
		ret = {'alerts':['invoke_rpc: got no stdout from swipl.']}
		log.warn(ret)
		return ret, []
	else:
		log.debug('')
		log.debug("invoke_rpc: prolog stdout:")
		log.debug(stdout_data)
		log.debug("invoke_rpc: end of prolog stdout.")
		log.debug('')
		try:
			rrr = json.loads(stdout_data)
			return rrr, files_in_dir_recursive(worker_tmp_path)
		except json.decoder.JSONDecodeError as e:
			log.warn('invoke_rpc: %s', e)
			log.debug('')
			return {'status':'error', 'message': f'invoke_rpc: {e}'}, []



def guess_request_format_rdf_or_xml(params):
	if params.get('request_format') is None:
		if len(params['request_files']) == 1 and params['request_files'][0].lower().endswith('.xml'):
			return 'xml'
		else:
			return 'rdf'
	else:
		return params['request_format']

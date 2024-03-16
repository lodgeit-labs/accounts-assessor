#!/usr/bin/env python3

import os,subprocess,time,shlex,logging,sys,threading,tempfile,datetime


def check_installation():

	flag = subprocess.check_output(['./flag.sh']).decode().strip()
	if not os.path.exists(flag):
		raise Exception(f'{flag} not found, run first_run.sh')

check_installation()



import atexit
from itertools import count
import click
import yaml
from copy import deepcopy
from urllib.parse import urlparse
import queue
import libtmux
import io
import lib.remove_all_anonymous_volumes


logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())


#from loguru import logger
# class InterceptHandler(logging.Handler):
#     def emit(self, record):
#         # Get corresponding Loguru level if it exists.
#         try:
#             level = logger.level(record.levelname).name
#         except ValueError:
#             level = record.levelno
# 
#         # Find caller from where originated the logged message.
#         frame, depth = sys._getframe(6), 6
#         while frame and frame.f_code.co_filename == logging.__file__:
#             frame = frame.f_back
#             depth += 1
# 
#         logger.opt(depth=depth, exception=record.exc_info).log(level, record.getMessage())
# 
# logging.basicConfig(handlers=[InterceptHandler()], level=0, force=True)
#logger.remove()
#logger.add(sys.stderr, format="{time} {level} {message}", level="INFO")
#logger.add("/tmp/robust_run.log", backtrace=True, diagnose=True, enqueue=True)


logging.getLogger('libtmux').setLevel(logging.WARNING)

tmuxer_logger = logging.getLogger('tmuxer')
tmuxer_logger.setLevel(logging.INFO)

logtail_logger = logging.getLogger('logtail')


logger.debug("debug from _run.py")
logger.info("info from _run.py")
logger.warning("warning from _run.py")


sq = shlex.quote
ss = shlex.split


def transfer_option(dict1, key, dict2):
	dict2[key] = dict1[key]
	del dict1[key]


def ccd(cmd, env):
	eee = ' '.join([f'{k}={(v).__repr__()}' for k,v in env.items()]) + '\\\n' + shlex.join(cmd)
	logger.debug(eee)
	e = os.environ.copy()
	e.update(env)
	subprocess.check_call(cmd, env=e)

def call_with_info(cmd):
	logger.info(cmd)
	subprocess.call(shlex.split(cmd))
	logger.info('.')

def call(cmd, env):
	e = os.environ.copy()
	e.update(env)
	subprocess.call(cmd, env=e)



tmux_stuff = queue.SimpleQueue()

def tmuxer(tmux_session_name, terminal_cmd):
	tmux_server = libtmux.Server()
	#if tmux_session_name == '':
	tmux_session = tmux_server.new_session(session_name='robust_'+str(datetime.datetime.utcnow().timestamp()).replace('.', '_'))
	#else:
	#tmux_session = tmux_server.sessions.filter(session_name=tmux_session_name)[0]

	terminal_cmd = terminal_cmd.format(session_name=tmux_session.name)
	if terminal_cmd != '':
		vvv = shlex.split(terminal_cmd)
		tmuxer_logger.debug(shlex.join(vvv))
		subprocess.Popen(vvv)

	while True:
		x=tmux_stuff.get()
		try:
			tmux_session_new_window(tmux_session=tmux_session, window_name=x['window_name'], window_shell=x['window_shell'])
		except:
			pass


#@logger.catch
def tmux_session_new_window(tmux_session, window_name, window_shell):
	#print(f"""ppp tmux_session.new_window(window_name={window_name}, window_shell={window_shell})""")
	tmuxer_logger.debug(f"""tmux_session.new_window(window_name={window_name}, window_shell={window_shell})""")
	tmux_session.new_window(window_name=window_name, window_shell=window_shell)


@click.group()
def cli():
	pass



@cli.command(
	help="""deploy the docker compose/stack""",
	context_settings=dict(
		ignore_unknown_options=True,
		show_default=True
    ))


@click.option('-of', '--offline', 		type=bool, 	default=False,
	help="don't pull base images.")

@click.option('-de', '--develop', 		type=bool, 	default=False,
	help="Development and debugging mode across the whole stack. CPU-intensive.")

@click.option('-ce', '--stay_running', 				type=bool, 	default=True,
	help="keep the script running after the stack is brought up.")

@click.option('-pp', '--port_postfix', 				type=str, 	default='', 
	help="last two or more digits of the services' public ports. Also identifies the particular docker stack.")

@click.option('-hn', '--use_host_network', 			type=bool, 	default=False, 
	help="tell docker to attach the containers to host network, rather than creating isolated one. Useful for development.")

@click.option('-ms', '--mount_host_sources_dir', 	type=bool, 	default=False, 
	help="bind-mount source code directories, instead of copying them into images. Useful for development.")

@click.option('-pu', '--public_url', 				type=str, 	default="http://localhost:8877",
	help="The public-facing url, including scheme and, optionally, port. Used in Caddy and apache.")

@click.option('-au', '--agraph_url', 				type=str, 	default="http://localhost:10077",
	help="The public-facing url, including scheme and port")

@click.option('-pg', '--enable_public_gateway', type=bool, default=True,
	help="enable Caddy (on ports 80 and 443). This generally does not make much sense on a development machine, because 1) you're only getting a self-signed cert that excel will refuse, 2)maybe you already have another web server listening on these ports, 3) using -pp (non-standard ports) in combination with https will give you trouble. 4) You must access the server by a hostname, not just IP.")

@click.option('-pi', '--enable_public_insecure', type=bool, default=False, 
	help="skip caddy and expose directly the apache server on port 88.")

@click.option('-pb', '--parallel_build', type=bool, default=False,
	help="parallelize building of docker images.")

@click.option('-rm', '--rm_stack', type=bool, default=True,
	help="rm the stack and deploy it afresh.")

@click.option('-rmav', '--remove_anonymous_volumes', type=bool, default=False, help='remove unlabelled volumes before deploying. This is useful for development, but dangerous. There is currently no easy way to delete just volumes created by the stack..') # we would have to inspect the running stack i guess.

@click.option('-co', '--compose', type=bool, default=False,
	help="use docker-compose instead of stack/swarm. Implies use_host_network. ")

@click.option('-os', '--omit_service', 'omit_services', type=str, default=[], multiple=True,
	help=" ")

@click.option('-os', '--only_service', 'only_services', type=str, default=[], multiple=True,
	help=" ")

@click.option('-oi', '--omit_image', 'omit_images', type=str, default=[], multiple=True,
	help="skip building image for service")

@click.option('-oi', '--only_image', 'only_images', type=str, default=[], multiple=True,
	help="skip building image for all other services")

@click.option('-sd', '--secrets_dir', type=str, default='../secrets/',
	help=" ")

#@click.argument('build_args', nargs=-1, type=click.UNPROCESSED)
@click.option('-nc', '--no_cache', type=str, default=[], multiple=True,	help="avoid builder cache for these images. Useful to force reinstalling pip packages, for example")

@click.option('-tc', '--terminal_cmd', 'terminal_cmd', type=str, default='mate-terminal -e "tmux attach-session -t {session_name}"', help="""`mate-terminal -e "tmux attach-session -t {session_name}"` by default. A format string for a command to run for viewing the progress of docker commands. Empty string to disable.""")

@click.option('-ts', '--tmux_session_name', 'tmux_session_name', type=str, default='', help='name of a pre-existing tmux session to run docker commands in. Defaults to an empty string - create a new session.')

@click.option('-ia', '--actors_scale', 'actors_scale', type=int, default=1, help='number of actors containers to spawn')

@click.option('-wp', '--worker_processes', 'worker_processes', type=int, default=1, help='number of uvicorn worker processes to spawn in each worker container')

@click.option('-ss', '--container_startup_sequencing', 'container_startup_sequencing', type=bool, default=True, help='obey depends_on declarations in compose file. If false, containers will be started in parallel. This is useful for development, unless you are debugging problems that occur on container startup, but may cause problems in production, if requests are made when not all services are ready. Note that waitforit is still used to wait for services to be ready.')

# no django anywhere anymore, except in internal_services, which are development tools not used right now, it's not yet clear if it's needed that they be started by this script at some point, but probably yes, as a sort of administrative backend maybe.
@click.option('-nr', '--django_noreload', 			type=bool, 	default=True,
	help="--noreload. Disables python source file watcher-reloader (to save CPU). Prolog code is still reloaded on every server invocation (even when not bind-mounted...)")

@click.option('-mu', '--manager_url', 'manager_url', type=str, default='http://localhost:9111', help='')

@click.option('-pyd', '--pydevd', 'pydevd', type=bool, default=False, help='enable pydev')

@click.option('-wg', '--WORKER_GRACE_PERIOD', 'WORKER_GRACE_PERIOD', type=int, default=100, help='')

@click.option('-fl', '--fly', 'fly', type=bool, default=False, help='manage worker fly.io machines')


#@click.option('-xs', '--xpce_scale', 'xpce_scale', type=real, default=1, help='XPCE UI scale')


@click.pass_context
def run(click_ctx, stay_running, offline, port_postfix, public_url, rm_stack, terminal_cmd, tmux_session_name, **choices):

	build_options = {}
	
	transfer_option(choices, 'omit_images', build_options)
	transfer_option(choices, 'only_images', build_options)
	transfer_option(choices, 'no_cache', build_options)
	transfer_option(choices, 'parallel_build', build_options)

	public_url_parsed = urlparse(public_url)
	public_host = public_url_parsed.hostname
	public_scheme = public_url_parsed.scheme
	compose = choices['compose']

	# caddy is just gonna listen on 80 and 443 always.
	generate_caddy_config(public_host)

	if choices['use_host_network']:
		frontend = 'localhost'
	else:
		frontend = 'frontend'

	with open('apache/conf/dynamic.conf', 'w') as f:
		f.write(
			f"""
ServerName {public_host}
			""")
		
		paths = 'health_check health chat upload reference api view div7a openapi.json docs ai3'.split()
			
		for path in paths:
			f.write(
				f"""
ServerName {public_host}
ProxyPassReverse "/{path}" "http://{frontend}:7788/{path}"
ProxyPass "/{path}" "http://{frontend}:7788/{path}"  connectiontimeout=999999999 timeout=999999999 retry=999999999 acquire=999999999 Keepalive=Off
""")

	if choices['mount_host_sources_dir']:
		hollow = 'hollow'
	else:
		hollow = 'full'
	
	
	agraph_port = 10077
	setup_agraph(agraph_port)
	if choices['agraph_url'] is None:
		choices['agraph_url'] = f'{public_scheme}://{public_host}:{str(agraph_port)}'
	
	
	hn = choices['use_host_network']

	e = {
		'BETTER_EXCEPTIONS': '1',
		'FLY': str(choices['fly']),
		"WORKER_GRACE_PERIOD": str(choices['WORKER_GRACE_PERIOD']),
		"WORKER_PROCESSES": str(choices['worker_processes']),
		'MANAGER_URL': choices['manager_url'],
		"PP": port_postfix,
		'DISPLAY':os.environ.get('DISPLAY', ''),
		'RABBITMQ_URL': "localhost:5672" if hn else "rabbitmq:5672",
		'REDIS_HOST':  'redis://localhost' if hn else 'redis://redis',
		'AGRAPH_HOST': 'localhost' if hn else 'agraph',
		'AGRAPH_PORT': str(agraph_port),
		'AGRAPH_URL': choices['agraph_url'],
		'REMOULADE_PG_URI': 'postgresql://postgres@localhost:5433/remoulade' if hn else 'postgresql://postgres@postgres:5433/remoulade',
		'REMOULADE_API': 'http://localhost:5005' if hn else 'http://remoulade-api:5005',
		'SERVICES_URL': 'http://localhost:17788' if hn else 'http://services:17788',
		'CSHARP_SERVICES_URL': 'http://localhost:17789' if hn else 'http://csharp-services:17789',
		'DOWNLOAD_BASTION_URL': 'http://localhost:6457' if hn else 'http://download:6457',
		'ALL_PROXY': 'http://localhost:3128' if hn else 'http://webproxy:3128',
	}

	#del choices['fly']
	del choices['agraph_url']
	del choices['manager_url']
	del choices['WORKER_GRACE_PERIOD']

	#
	# if choices['display']:
	# 	e['DISPLAY']' = os.environ.get('DISPLAY', '')

	if choices['pydevd']:
		e['PYDEVD'] = 'true'
	del choices['pydevd']

	if choices['develop']:
		e['FLASK_DEBUG'] = '1'
		e['FLASK_ENV'] = 'development'
		e['WATCHMEDO'] = 'true'
	else:
		e['FLASK_DEBUG'] = '0'
		e['FLASK_ENV'] = 'production'
		e['WATCHMEDO'] = ''
	del choices['develop']

	#for ch in choices.items()
		#f'svcenv_{service}_{var}'

	remove_anonymous_volumes = choices['remove_anonymous_volumes']
	del choices['remove_anonymous_volumes']
	

	stack_fn = generate_stack_file(port_postfix, public_url, choices, e)
	if rm_stack and not compose:
		shell('docker stack rm robust' + port_postfix)

	compose_cmd = 'docker compose -f ' + stack_fn + ' -p robust --compatibility '

	if not offline:
		# this needs work. when --ignore-buildable ? (Docker Compose version v2.17.0-rc.1 has it) https://github.com/docker/compose#docker-compose-v2
		
		logger.info('pulling images (those that will be built locally are expected to fail..)') 
		call(ss(compose_cmd + ' pull --ignore-pull-failures --include-deps '), env={})

	threading.Thread(target=tmuxer, args=(tmux_session_name, terminal_cmd), daemon=True).start()

	#del choices['worker_processes']

	build_options.update({'port_postfix':port_postfix,'mode':hollow})
	build(offline, **build_options)

	if rm_stack:
		
		# this was motivated by postgres, which would otherwise initialize once, and then old configuration would linger forever. 
		if remove_anonymous_volumes:
			lib.remove_all_anonymous_volumes.remove_anonymous_volumes()
		
		logger.info('flush old messages:')
		call_with_info('docker volume rm robust_rabbitmq')

		logger.info('wait for old network to disappear..')
		while True:
			cmdxxx = "docker network ls | grep robust" + port_postfix
			p = subprocess.run(cmdxxx, shell=True, stdout=subprocess.PIPE)
			logger.info(cmdxxx + ': ' + str(p.returncode) + ':')
			logger.info(p.stdout)
			if p.returncode:
				logger.info('ok, network is gone.')
				logger.info('.')
				break
			time.sleep(1)

	#shell('pwd')
	call_with_info('./lib/git_info.fish')
	

	threading.Thread(daemon=True, target = logtail, args = (compose_cmd,)).start()
	threading.Thread(daemon=True, target = stack_up, args = (compose, compose_cmd, stack_fn, port_postfix)).start()
	if not stay_running:
		threading.Thread(daemon=True, target = health_check, args=(public_url,)).start()

	started = datetime.datetime.now()

	def down():
		if not stack_up_failed:
			if stay_running:
				timeout = 99999
			else:
				timeout = 1
			ccd(ss(compose_cmd + ' down  -t ' + str(timeout)), env={})

	atexit.register(down)

	while True:
		time.sleep(1)
		if not stay_running:
			if health_check_passed.is_set():
				logger.info('healthy')
				#down()
				break
				
			if health_check_failed.is_set():
				logger.info('error')
				#down()
				exit(1)
				
			elif (datetime.datetime.now() - started).seconds > 5*60:
				logger.critical('CI timeout exceeded..')
				logger.critical()
				#down()
				exit(1)
		
		if stack_up_failed:
			logger.warn('stack_up_failed')
			exit(1)
		




def health_check(public_url):
	while True:
		time.sleep(10)
		try:
			logger.info('health_check...')
			subprocess.check_call(shlex.split(f"""curl -v --trace-time --retry-connrefused  --retry-delay 10 --retry 30 -L -S --fail --max-time 320 --header 'Content-Type: application/json' --data '---' {public_url}/health_check"""))
			logger.info('healthcheck ok')
			health_check_passed.set()
			return
		except subprocess.CalledProcessError as e:
			pass
		except Exception as e:
			logger.critical(e)
			logger.critical('healthcheck failed')
			health_check_failed.set()



health_check_passed = threading.Event()
health_check_failed = threading.Event()
stack_up_failed = False
healthy = False


def stack_up(compose, compose_cmd, stack_fn, port_postfix):
	try:
		if compose:
			try:
				ccd(ss(compose_cmd + ' up --timestamps --remove-orphans '), env={})
			except subprocess.CalledProcessError:
				ccd(ss('docker ps'), env={})		
				stack_up_failed = True
		else:
			ccd(ss('docker stack deploy --prune --compose-file') + [stack_fn, 'robust'+port_postfix], env={})
			shell('docker stack ps robust'+port_postfix + ' --no-trunc')
			shell('./follow_logs_noagraph.sh '+port_postfix)
	except Exception as e:
		logger.error(e)




def setup_agraph(agraph_port):
	with open('agraph/etc/agraph.cfg', 'w') as o:
		with open('agraph/etc/agraph.cfg.template', 'r') as i:
			o.write(i.read())
		o.write(f"""
Port {agraph_port}
SuperUser {open('../secrets/AGRAPH_SUPER_USER').read().strip()}:{open('../secrets/AGRAPH_SUPER_PASSWORD').read().strip()}
""")




def logtail(compose_events_cmd):
	cmd = shlex.split('stdbuf -oL -eL ' + compose_events_cmd + ' events')
	proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
	for line in io.TextIOWrapper(proc.stdout, encoding="utf-8"):
		if 'container start' in line or 'container die' in line:
			#print('logtail: ' + line)
			logtail_logger.info('logtail: ' + line)
		if 'container start' in line:
			s = line.split()
			container_id = s[4]
			line_quoted = shlex.quote(line)
			tmux_stuff.put({'window_name':container_id[:5], 'window_shell':f'echo {line_quoted}; docker logs -f ' + container_id + ' | cat; echo "end."; cat'})
	# we kinda might rather want docker-compose -f ../generated_stack_files/last.yml -p robust logs -f <service name>
	# but as it is, this does pop up a new tmux window when a container is restarted etc, and brings it to the front, and there's always a bit of the old log and then the new, which is nice. Does it ever happen that the log stops being printed while a container is running (with `docker logs`)?



def deploy_stack(pp, fn, django_args):
	subprocess.check_call(ss(), env={"PP": ""})

def generate_caddy_config(public_host):
	cfg = f'''

	# autogenerated by _run.py.

	{{
		#debug

		#admin 127.0.0.1:2019 {{
		#	origins 127.0.0.1
		#}}
	}}

	{public_host} {{
		import Caddyfile_auth
		reverse_proxy apache:80
	}}

	{public_host}:10035 {{
		import Caddyfile_auth
		reverse_proxy agraph:10035
	}}
	'''
	
	with open('caddy/Caddyfile', 'w') as f:
		f.write(cfg)


def replace_env_vars(tws, env):
	"""
	replace ${varname} occurence in any string with value from env. 
	"""
	if isinstance(tws, dict):
		for k, v in tws.items():
			tws[k] = replace_env_vars(v, env)
	elif isinstance(tws, list):
		for i, v in enumerate(tws):
			tws[i] = replace_env_vars(v, env)
	elif isinstance(tws, str):
		for ek,ev in env.items():
			tws = tws.replace('${'+ek+'}', ev)
	elif tws is None:
		return None
	elif isinstance(tws, int):
		return tws
	else:
		raise Exception(type(tws))
	return tws


def identity_envvars(tws):
	"""
	replace None with ${varname} in environment variables.
	This way, we don't rely on docker-compose to pass these env vars through.
	"""
	for s in tws['services'].values():
		if 'environment' not in s or s['environment'] is None:
			s['environment'] = {}
		logger.debug(s['environment'])
		for k,v in s['environment'].items():
			if v is None:
				s['environment'][k] = '${'+k+'}'


def generate_stack_file(port_postfix, PUBLIC_URL, choices, env):
	with open('docker-stack-template.yml') as file_in:
		src = yaml.load(file_in, Loader=yaml.FullLoader)
		fn = '../generated_stack_files/docker-stack' + ('__'.join(['']+[k for k,v in choices.items() if v])) + '.yml'

	tws = tweaked_services(src, port_postfix, PUBLIC_URL, **choices)
	identity_envvars(tws)
	tws = replace_env_vars(tws, env)
	
	with open(fn, 'w') as file_out:
		yaml.dump(tws, file_out)
	link_name = '../generated_stack_files/last.yml'
	try:
		os.remove(link_name)
	except FileNotFoundError:
		pass
	os.symlink(src=fn,dst=link_name) # Create a symbolic link pointing to src named dst. !!!!!! like, really.
	return fn


def tweaked_services(src, port_postfix, PUBLIC_URL, use_host_network, mount_host_sources_dir, django_noreload, enable_public_gateway, enable_public_insecure, compose, omit_services, only_services, secrets_dir, actors_scale, container_startup_sequencing, worker_processes, fly):

	res = deepcopy(src)
	services = res['services']
	services['frontend']['environment']['PUBLIC_URL'] = PUBLIC_URL
	services['actors']  ['environment']['PUBLIC_URL'] = PUBLIC_URL
	services['services']['environment']['PUBLIC_URL'] = PUBLIC_URL

	if not enable_public_gateway:
		del services['caddy']

	if enable_public_insecure and not compose:
		services['apache']['ports'] = ["88"+port_postfix+":80"]
		services['agraph']['ports'] = ["100"+port_postfix+":10035"]

	if not 'secrets' in res:
		res['secrets'] = {}

	for fn,path in files_in_dir(secrets_dir):
		if fn not in res['secrets']:
			res['secrets'][fn] = {'file':(path)}

	if use_host_network:
		del res['networks']['frontend']
		del res['networks']['backend']

	for k,v in services.items():
		if 'environment' not in v:
			v['environment'] = {}

		if use_host_network:
			if compose:
				v['network_mode'] = 'host'
			else:
				v['networks'] = ['hostnet']

		if not fly and 'secrets' in v:
			try:
				v['secrets'].remove('FLYCTL_API_TOKEN')
			except ValueError:
				pass


	if compose:
		del res['networks']
		for k,v in services.items():
			v['ports'] = []
				# for port in v['hostnet_ports']:
				# 	v['ports'].append(str(port)+':'+str(port))
			if 'networks' in v:
				del v['networks']
			if 'deploy' in v:
				#del v['deploy']
				pass
			#v = v['deploy']
			#if 'update_config' in v:
			#	del v['update_config']
			if 'deploy' in v:
				if 'restart_policy' in v['deploy']:
					if 'delay' in v['deploy']['restart_policy']:
						del v['deploy']['restart_policy']['delay']

	for x in ['actors']:
		if x in services:
			services[x].get('deploy', {})['replicas'] = actors_scale


	for k,v in services.items():
		if 'hostnet_ports' in v:
			del v['hostnet_ports']
		if not container_startup_sequencing:
			v['depends_on'] = {}

	for x in ['worker', 'workers', 'manager', 'actors', 'services', 'frontend', 'remoulade-api', 'download']:
		if x in services:
			service = services[x]
			if mount_host_sources_dir:
				if 'volumes' not in service:
					service['volumes'] = []
				service['volumes'].append('../sources:/app/sources')
				assert service['image'] == f'koo5/{x}${{PP}}:latest', service['image']
				service['image'] = f'koo5/{x}-hlw{port_postfix}:latest'

	if 'DISPLAY' in os.environ:
		if 'worker' in services:
			services['worker']['environment']['DISPLAY'] = "${DISPLAY}"

	if worker_processes == 0:
		if not 'worker' in omit_services:
			omit_services += ('worker',)

	for s in omit_services:
		delete_service(services, s)

	if only_services:
		for k,v in list(services.items()):
			if k not in only_services:
				delete_service(services, k)

	return res

def delete_service(services, omit_service):
	del services[omit_service]
	for k,v in services.items():
		d = v.get('depends_on',[])
		if omit_service in d:
			if type(d) == list:
				v['depends_on'].remove(omit_service)
			else:
				del v['depends_on'][omit_service]




def files_in_dir(dir):
	result = []
	for filename in os.listdir(dir):
		filename2 = os.path.join(dir, filename)
		if os.path.isfile(filename2):
			result.append((filename,filename2))
	return result


def shell(cmd):
	logger.info('>')
	logger.info(cmd)
	logger.info('>')
	r = os.system(cmd)
	if r != 0:
		exit(r)





subtask_counter = count(1).__next__

class ExcThread(threading.Thread):

	"""Thread that propagates exceptions to the parent thread but also logs them to the logger."""

	def __init__(self, group=None, target=None, name=None,
                 args=(), kwargs=None, *, daemon=None):
		super().__init__(group, target, f"subtask {subtask_counter()}", args, kwargs, daemon=daemon)
		self.kwargs = kwargs
		self.args = args

	def run(self):
		self.exc = None
		try:
			super().run()
		except:
			self.exc = sys.exc_info()

	def join(self):
		threading.Thread.join(self)
		if self.exc:
			task = ''
			#if self.task:
			#	task = ' (' + str(self.task) + ')'
			msg = f"{self.getName()}{task} threw an exception: {self.exc[1]}"
			logger.crit(msg)
			#exit(1)
			new_exc = Exception(msg)
			raise new_exc.with_traceback(self.exc[2])


class ExcThread2(ExcThread):

	def pretty_str(self):
		return f"cd {self.kwargs['cwd']}; {self.args[0]}"
		
		
		
def join_all():
	join(threads)
	threads.clear()

def join(t):
	errors = []
	for thread in t[:]:
		if thread in threads: # only join threads that we have not joined yet
			join_one(thread, errors)
	if len(errors):
		# let's kill all running threads, even those not passed to us here
		for thread in threads:
			if thread not in t:
				join_one(thread, errors)
		# reiterate all the errors
		logger.critical('failed command %s :', thread.pretty_str())
		for error in errors:
			logger.error(error)
		sys.exit(1)


def join_one(thread, errors):
	try:
		thread.join()
		#logger.info(f"{thread.name} done ({thread.kwargs} {thread.args})")
		logger.info(f"{thread.name} done ({thread.pretty_str()})")
	except Exception as e:
		errors.append(e)
		logger.critical('subtask failed!')



def co(cmd):
	return subprocess.check_output(cmd, text=True, universal_newlines=True)
def cc(cmd, **kwargs):
	return subprocess.check_call(cmd, text=True, universal_newlines=True, bufsize=1, **kwargs)

def ccss(cmd, **kwargs):
	return cc(ss(cmd), **kwargs)


threads = []
files = []

def task(name, dir, cmd):
	global files

	cmd = 'stdbuf -oL -eL ' + cmd
	stdo = tempfile.NamedTemporaryFile(buffering=1, prefix=name+'_out_', mode='w+')
	stde = tempfile.NamedTemporaryFile(buffering=1, prefix=name+'_err_', mode='w+')

	intro = 'cd ' + shlex.quote(dir) + '; ' + cmd
	logger.debug(intro)
	stdo.write(intro)

	files += [stde, stdo]
	tailcmd = 'tail -f '+ stdo.name + ' ' + stde.name + ' | awk \'{print "' + name + """: ", $0}'"""
	tmux_stuff.put({'window_name':name[:5], 'window_shell':tailcmd})
	subprocess.Popen(['bash', '-c', tailcmd]) 

	thread = ExcThread2(target = ccss, args = (cmd,), kwargs = {'cwd':dir, 'stdout':stdo, 'stderr':stde})
	thread.task = cmd
	threads.append(thread)
	thread.start()

	if _parallel:
		return thread
	else:
		join([thread])
		threads.remove(thread)
		return thread
		


def realpath(x):
	return co(['realpath', x])[:-1]



def build(offline, port_postfix, mode, parallel_build, no_cache, omit_images, only_images):
	global _parallel
	_parallel=parallel_build


	cc('./lib/git_info.fish')

	def svc(service_name, dir, cmd, dockerfile):
		if service_name not in omit_images and (not only_images or service_name in only_images):
			appdir = service_name.replace("-","_")
			args = dict(
				APPDIR=appdir, 
				APPPATH = f'/app/sources/{appdir}'
			)
			return task(service_name + '_build', dir, (cmd + ' {args} -f "{dockerfile}" . ').format(
				port_postfix=port_postfix,
				service_name=service_name,
				dockerfile=dockerfile,
				args=' '.join([f'--build-arg {n}={v}' for n,v in args.items()])
			))
			
					
			

			

	pull = '' if offline else '--pull '
	dbptks = f'docker build {pull} -t "koo5/{{service_name}}'
	dbtks = 'docker build -t "koo5/{service_name}'

	ubuntu = task('ubuntu' + '_build', '../sources/', f'docker build {pull} -t "koo5/ubuntu" '+('--no-cache' if 'ubuntu' in no_cache else '')+' -f "../docker_scripts/ubuntu/Dockerfile" . ')

	svc('apache', 		  'apache', 						dbptks+'{port_postfix}"', 	"Dockerfile")
	svc('agraph', 		  'agraph', 						dbptks+'{port_postfix}"', 	"Dockerfile")
	svc('super-bowl', 	  '../sources/super-bowl/',			dbptks+'"',					"container/Dockerfile")
	svc('csharp-services','../sources/CsharpServices/WebApplication2',	dbptks+'"',	"../../../docker_scripts/csharp_services/Dockerfile")

	join([ubuntu])

	svc('download',				'../sources/', dbtks+'-hlw{port_postfix}"', "../docker_scripts/download/Dockerfile_hollow")
	svc('remoulade-api', 		'../sources/', dbtks+'-hlw{port_postfix}"', "../docker_scripts/remoulade_api/Dockerfile_hollow")
	svc('actors',				'../sources/', dbtks+'-hlw{port_postfix}"', "actors/Dockerfile_hollow")
	svc('worker',				'../sources/', dbtks+'-hlw{port_postfix}"', "worker/Dockerfile_hollow")
	svc('manager',				'../sources/', dbtks+'-hlw{port_postfix}"', "manager/Dockerfile_hollow")
	svc('internal-services',		'../sources/', dbtks+'-hlw{port_postfix}"', "internal_services/Dockerfile_hollow")
	svc('services',				'../sources/', dbtks+'-hlw{port_postfix}"', "services/Dockerfile_hollow")
	svc('frontend',				'../sources/', dbtks+'-hlw{port_postfix}"', "frontend/Dockerfile_hollow")

	os.set_blocking(sys.stdout.fileno(), False)
	logger.debug("join_all...")
	join_all()

	#if mode == "full": # not hollow
	# 	svc('manager',			'../sources/', dbtks+'{port_postfix}"', "manager/Dockerfile")
	#svc('worker',			'../sources/', dbtks+'{port_postfix}"', "worker/Dockerfile")
	# 	svc('workers',			'../sources/', dbtks+'{port_postfix}"', "workers/Dockerfile")
	# 	svc('services',			'../sources/', dbtks+'{port_postfix}"', "services/Dockerfile")
	# 	svc('csharp-services',	'../sources/', dbtks+'{port_postfix}"', "csharp-services/Dockerfile")
	# 	svc('frontend',			'../sources/', dbtks+'{port_postfix}"', "frontend/Dockerfile")

	join_all()
	logger.info("all done")


if __name__ == '__main__':
	cli()







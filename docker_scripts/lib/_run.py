#!/usr/bin/env python3
import datetime
import os,subprocess,time,shlex,logging,sys,threading,tempfile
from itertools import count
import click
import yaml
from copy import deepcopy
from urllib.parse import urlparse
import queue
import libtmux


#l = logging.getLogger()
#l.setLevel(logging.DEBUG)
#l.addHandler(logging.StreamHandler())

from loguru import logger

logger.debug("That's it, beautiful and simple logging!")
class InterceptHandler(logging.Handler):
    def emit(self, record):
        # Get corresponding Loguru level if it exists.
        try:
            level = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno

        # Find caller from where originated the logged message.
        frame, depth = sys._getframe(6), 6
        while frame and frame.f_code.co_filename == logging.__file__:
            frame = frame.f_back
            depth += 1

        logger.opt(depth=depth, exception=record.exc_info).log(level, record.getMessage())

logging.basicConfig(handlers=[InterceptHandler()], level=0, force=True)
logger.add("/tmp/robust_run.log", backtrace=True, diagnose=True, enqueue=True)


sq = shlex.quote
ss = shlex.split



def ccd(cmd, env):
	eee = ' '.join([f'{k}={(v).__repr__()}' for k,v in env.items()]) + '\\\n' + shlex.join(cmd)
	logging.getLogger().info(eee)
	e = os.environ.copy()
	e.update(env)
	subprocess.check_call(cmd, env=e)

def call(cmd, env):
	e = os.environ.copy()
	e.update(env)
	subprocess.call(cmd, env=e)



tmux_stuff = queue.SimpleQueue()

def tmuxer(tmux_session_name, terminal_cmd):

	logging.getLogger('libtmux').setLevel(logging.WARNING)

	tmux_server = libtmux.Server()
	#if tmux_session_name == '':
	tmux_session = tmux_server.new_session(session_name='robust_'+str(datetime.datetime.utcnow().timestamp()).replace('.', '_'))
	#else:
	#tmux_session = tmux_server.sessions.filter(session_name=tmux_session_name)[0]

	terminal_cmd = terminal_cmd.format(session_name=tmux_session.name)
	if terminal_cmd != '':
		vvv = shlex.split(terminal_cmd)
		print(shlex.join(vvv))
		subprocess.Popen(vvv)

	while True:
		x=tmux_stuff.get()
		try:
			tmux_session_new_window(tmux_session=tmux_session, window_name=x['window_name'], window_shell=x['window_shell'])
		except:
			pass


@logger.catch
def tmux_session_new_window(tmux_session, window_name, window_shell):
	print(f"""ppp tmux_session.new_window(window_name={window_name}, window_shell={window_shell})""")
	logging.getLogger('tmuxer').debug(f"""tmux_session.new_window(window_name={window_name}, window_shell={window_shell})""")
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
	help="don't use internet..")

@click.option('-de', '--develop', 		type=bool, 	default=False,
	help="Development and debugging mode. CPU-intensive.")

@click.option('-sr', '--stay_running', 				type=bool, 	default=True,
	help="keep the script running after the stack is brought up.")

#@click.option('-d1', '--debug_frontend_server', 				type=bool, 	default=False,
# 	help="")

@click.option('-pp', '--port_postfix', 				type=str, 	default='', 
	help="last two or more digits of the services' public ports. Also identifies the particular docker stack.")

@click.option('-hn', '--use_host_network', 			type=bool, 	default=False, 
	help="tell docker to attach the containers to host network, rather than creating one?")

@click.option('-ms', '--mount_host_sources_dir', 	type=bool, 	default=False, 
	help="bind-mount source code directories, instead of copying them into images. Useful for development.")

@click.option('-nr', '--django_noreload', 			type=bool, 	default=True,
	help="--noreload. Disables python source file watcher-reloader (to save CPU). Prolog code is still reloaded on every server invocation (even when not bind-mounted...)")

#@click.option('-nr', '--django_noreload', 			type=bool, 	default=True,
#	help="--noreload. Disables python source file watcher-reloader (to save CPU). Prolog code is still reloaded on every server invocation (even when not bind-mounted...)")

@click.option('-pu', '--public_url', 				type=str, 	default="http://localhost",
	help="The public-facing url, including scheme and, optionally, port. Used in django to construct URLs, and hostname is used in Caddy and apache.")

@click.option('-pg', '--enable_public_gateway', type=bool, default=True,
	help="enable Caddy (on ports 80 and 443). This generally does not make much sense on a development machine, because 1) you're only getting a self-signed cert that excel will refuse, 2)maybe you already have another web server listening on these ports, 3) using -pp (non-standard ports) in combination with https will give you trouble. 4) You must access the server by a hostname, not just IP.")

@click.option('-pi', '--enable_public_insecure', type=bool, default=False, 
	help="skip caddy and expose directly the apache server on port 88.")

@click.option('-pb', '--parallel_build', type=bool, default=False,
	help="parallelize building of docker images.")

@click.option('-rm', '--rm_stack', type=bool, default=True,
	help="rm the stack and deploy it afresh.")

@click.option('-co', '--compose', type=bool, default=False,
	help="use docker-compose instead of stack/swarm. Implies use_host_network. ")

@click.option('-os', '--omit_service', 'omit_services', type=str, default=[], multiple=True,
	help=" ")

@click.option('-in', '--include_service', 'include_services', type=str, default=[], multiple=True,
	help=" ")

@click.option('-oi', '--omit_image', 'omit_images', type=str, default=[], multiple=True,
	help="skip building image for service")

@click.option('-sd', '--secrets_dir', type=str, default='../secrets/',
	help=" ")

#@click.argument('build_args', nargs=-1, type=click.UNPROCESSED)
@click.option('-nc', '--no_cache', type=str, default=[], multiple=True,	help="avoid builder cache for these images")

@click.option('-tc', '--terminal_cmd', 'terminal_cmd', type=str, default='mate-terminal -e "tmux attach-session -t {session_name}"', help="""`mate-terminal -e "tmux attach-session -t {session_name}"` by default. A format string for a command to run for viewing the progress of docker commands. Empty string to disable.""")

@click.option('-ts', '--tmux_session_name', 'tmux_session_name', type=str, default='', help='name of a pre-existing tmux session to run docker commands in. Defaults to an empty string - create a new session.')

@click.option('-ws', '--workers_scale', 'workers_scale', type=int, default=1, help='number of worker containers to spawn')

@click.option('-ss', '--container_startup_sequencing', 'container_startup_sequencing', type=bool, default=True, help='obey depends_on declarations in compose file. If false, containers will be started in parallel. This is useful for development, unless you are debugging problems that occur on container startup, but may cause problems in production, if requests are made when not all services are ready. Note that waitforit is still used to wait for services to be ready.')

#@click.option('-xs', '--xpce_scale', 'xpce_scale', type=real, default=1, help='XPCE UI scale')

@click.pass_context
def run(click_ctx, stay_running, offline, port_postfix, public_url, parallel_build, rm_stack, terminal_cmd, tmux_session_name, **choices):
	no_cache = choices['no_cache']
	del choices['no_cache']
	omit_images = choices['omit_images']
	del choices['omit_images']

	public_host = urlparse(public_url).hostname
	compose = choices['compose']

	# caddy is just gonna listen on 80 and 443 always.
	generate_caddy_config(public_host)

	if choices['use_host_network']:
		frontend = 'localhost'
	else:
		frontend = 'frontend'
	open('apache/conf/dynamic.conf','w').write(
f"""
ServerName {public_host}
""" + '\n'.join([f"""
ProxyPassReverse "/{path}" "http://{frontend}:7788/{path}"
ProxyPass "/{path}" "http://{frontend}:7788/{path}"  connectiontimeout=999999999 timeout=999999999 retry=999999999 acquire=999999999 Keepalive=Off
""" for path in 'health_check health chat upload reference api view web'.split()]))
 
	pp = port_postfix

	if choices['mount_host_sources_dir']:
		hollow = 'hollow'
	else:
		hollow = 'full'
	
	hn = choices['use_host_network']

	e = {
		"PP": pp,
		'DISPLAY':os.environ.get('DISPLAY', ''),
		'RABBITMQ_URL': "localhost:5672" if hn else "rabbitmq:5672",
		'REDIS_HOST':  'redis://localhost' if hn else 'redis://redis',
		'AGRAPH_HOST': 'localhost' if hn else 'agraph',
		'AGRAPH_PORT': '10035',
		'REMOULADE_PG_URI': 'postgresql://remoulade@localhost:5433/remoulade' if hn else 'postgresql://remoulade@postgres:5433/remoulade',
		'REMOULADE_API': 'http://localhost:5005' if hn else 'http://remoulade-api:5005',
		'SERVICES_URL': 'http://localhost:17788' if hn else 'http://services:17788',
		'CSHARP_SERVICES_URL': 'http://localhost:17789' if hn else 'http://csharp-services:17789',
	}
	#
	# if choices['display']:
	# 	e['DISPLAY']' = os.environ.get('DISPLAY', '')

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


	stack_fn = generate_stack_file(port_postfix, public_url, choices)
	if rm_stack and not compose:
		shell('docker stack rm robust' + pp)

	compose_cmd = 'docker-compose -f ' + stack_fn + ' -p robust --compatibility '

	if not offline:
		# this needs work. when --ignore-buildable ? (Docker Compose version v2.17.0-rc.1 has it) https://github.com/docker/compose#docker-compose-v2
		call(ss(compose_cmd + ' pull --ignore-pull-failures --include-deps '), env=e)

	threading.Thread(target=tmuxer, args=(tmux_session_name, terminal_cmd), daemon=True).start()

	build(offline, **{'port_postfix':pp,'mode':hollow,'parallel':parallel_build,'no_cache':no_cache, 'omit_images':omit_images})

	if rm_stack:
		print('wait for old network to disappear..')
		while True:
			cmdxxx = "docker network ls | grep robust" + pp
			p = subprocess.run(cmdxxx, shell=True, stdout=subprocess.PIPE)
			print(cmdxxx + ': ' + str(p.returncode) + ':')
			print(p.stdout)
			if p.returncode:
				break
			time.sleep(1)

	shell('pwd')
	shell('./lib/git_info.fish')

	open('../generated_stack_files/build_done.flag', "w").write('1')

	if compose:


		if stay_running:
			import atexit
			def shutdown():
				ccd(ss(compose_cmd + ' down  -t 999999 '), env=e)
			atexit.register(shutdown)

		try:
			threading.Thread(daemon=True, target = logtail, args = (compose_cmd,)).start()
			
			ccd(ss(compose_cmd + ' up --remove-orphans ' + ('' if stay_running else ' --detach')), env=e)
		except subprocess.CalledProcessError:
			ccd(ss('docker ps'), env={})

			if stay_running:
				atexit.unregister(shutdown)
				while True:
					time.sleep(1000)

			exit(1)

	else:
		ccd(ss('docker stack deploy --prune --compose-file') + [stack_fn, 'robust'+pp], env=e)
		shell('docker stack ps robust'+pp + ' --no-trunc')
		shell('./follow_logs_noagraph.sh '+pp)

import io

def logtail(compose_events_cmd):
	cmd = shlex.split('stdbuf -oL -eL ' + compose_events_cmd + ' events')
	proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
	for line in io.TextIOWrapper(proc.stdout, encoding="utf-8"):
		if 'container start' in line or 'container die' in line:
			print('logtail: ' + line)
			logging.getLogger('logtail').debug('logtail: ' + line)
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


def generate_stack_file(port_postfix, PUBLIC_URL, choices):
	with open('docker-stack-template.yml') as file_in:
		src = yaml.load(file_in, Loader=yaml.FullLoader)
		fn = '../generated_stack_files/docker-stack' + ('__'.join(['']+[k for k,v in choices.items() if v])) + '.yml'

	with open(fn, 'w') as file_out:
		yaml.dump(tweaked_services(src, port_postfix, PUBLIC_URL, **choices), file_out)
	link_name = '../generated_stack_files/last.yml'
	try:
		os.remove(link_name)
	except FileNotFoundError:
		pass
	os.symlink(src=fn,dst=link_name) # Create a symbolic link pointing to src named dst. !!!!!! like, really.
	return fn


def tweaked_services(src, port_postfix, PUBLIC_URL, use_host_network, mount_host_sources_dir, django_noreload, enable_public_gateway, enable_public_insecure, compose, omit_services, include_services, secrets_dir, workers_scale, container_startup_sequencing):

	res = deepcopy(src)
	services = res['services']
	services['frontend']['environment']['PUBLIC_URL'] = PUBLIC_URL

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

	if compose:
		del res['networks']
		for k,v in services.items():
			v['ports'] = []
				# for port in v['hostnet_ports']:
				# 	v['ports'].append(str(port)+':'+str(port))

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

	for x in ['workers']:
		if x in services:
			services[x].get('deploy', {})['replicas'] = workers_scale


	for k,v in services.items():
		if 'hostnet_ports' in v:
			del v['hostnet_ports']
		if not container_startup_sequencing:
			v['depends_on'] = {}

	if mount_host_sources_dir:
		for x in ['workers','services','frontend', 'remoulade-api']:
			if x in services:
				service = services[x]
				if 'volumes' not in service:
					service['volumes'] = []
				service['volumes'].append('../sources:/app/sources')
				assert service['image'] == f'koo5/{x}${{PP}}:latest', service['image']
				service['image'] = f'koo5/{x}-hlw{port_postfix}:latest'

		services['workers']['volumes'].append('../sources/swipl/xpce:/home/myuser/.config/swi-prolog/xpce')

	if 'DISPLAY' in os.environ:
		if 'workers' in services:
			services['workers']['environment']['DISPLAY'] = "${DISPLAY}"

	for s in omit_services:
		delete_service(services, s)

	if len(include_services) != 0:
		for k,v in list(services.items()):
			if k not in include_services:
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
	print('>')
	print(cmd)
	print('>')
	r = os.system(cmd)
	if r != 0:
		exit(r)





subtask_counter = count(1).__next__

class ExcThread(threading.Thread):
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
			print(msg)
			#exit(1)
			new_exc = Exception(msg)
			raise new_exc.with_traceback(self.exc[2])


def join_all():
	join(threads)

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
		print()
		print('command failed:')
		for error in errors:
			print(error)
		sys.exit(1)


def join_one(thread, errors):
	try:
		thread.join()
		print(f"{thread.name} done ({thread.kwargs} {thread.args})")
	except Exception as e:
		errors.append(e)
		print('subtask failed!')
		print()



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
	intro = '\n\ncd ' + shlex.quote(dir) + '\n' + shlex.quote(cmd) + '\n...'
	stdo = tempfile.NamedTemporaryFile(buffering=1, prefix=name+'_out_', mode='w+')
	stde = tempfile.NamedTemporaryFile(buffering=1, prefix=name+'_err_', mode='w+')
	files += [stde, stdo]
	tailcmd = 'tail -f '+ stdo.name + ' ' + stde.name
	tmux_stuff.put({'window_name':name[:5], 'window_shell':tailcmd})
	subprocess.Popen(shlex.split(tailcmd))

	sys.stdout.write(intro)
	stdo.write(intro)

	thread = ExcThread(target = ccss, args = (cmd,), kwargs = {'cwd':dir, 'stdout':stdo, 'stderr':stde})
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



def build(offline, port_postfix, mode, parallel, no_cache, omit_images):
	global _parallel
	_parallel=parallel


	cc('./lib/git_info.fish')

	def svc(service_name, dir, cmd, dockerfile):
		if service_name not in omit_images:
			return task(service_name + '_build', dir, (cmd + ' -f "{dockerfile}" . ').format(
				port_postfix=port_postfix,
				service_name=service_name,
				dockerfile=dockerfile
			))

	pull = '' if offline else '--pull '
	dbptks = f'docker build {pull} -t "koo5/{{service_name}}'
	dbtks = 'docker build -t "koo5/{service_name}'

	ubuntu = task('ubuntu' + '_build', 'ubuntu', f'docker build {pull} -t "koo5/ubuntu" '+('--no-cache' if 'ubuntu' in no_cache else '')+' -f "Dockerfile" . ')

	svc('apache', 		  'apache', 						dbptks+'{port_postfix}"', 	"Dockerfile")
	svc('agraph', 		  'agraph', 						dbptks+'{port_postfix}"', 	"Dockerfile")
	svc('super-bowl', 	  '../sources/super-bowl/',			dbptks+'"',					"container/Dockerfile")
	svc('csharp-services','../sources/CsharpServices/WebApplication2',	dbptks+'"',	"../../../docker_scripts/csharp_services/Dockerfile")

	join([ubuntu])

	svc('remoulade-api', 		'../sources/', dbtks+'-hlw{port_postfix}"', 		"../docker_scripts/remoulade_api/Dockerfile_hollow")
	svc('workers', 				'../sources/', dbtks+'-hlw{port_postfix}"', 		"workers/Dockerfile_hollow")
	svc('internal-services', 	'../sources/', dbtks+'-hlw{port_postfix}"', 		"internal_services/Dockerfile_hollow")
	svc('services', 			'../sources/', dbtks+'-hlw{port_postfix}"', 		"../docker_scripts/services/Dockerfile_hollow")
	svc('frontend', 			'../sources/', dbtks+'-hlw{port_postfix}"', 		"../docker_scripts/frontend/Dockerfile_hollow")

	os.set_blocking(sys.stdout.fileno(), False)
	print("ok?")
	join_all()

	if mode == "full": # not hollow
		svc('workers',	'../sources/', dbtks+'{port_postfix}"', "workers/Dockerfile")
		svc('services',	'../sources/', dbtks+'{port_postfix}"', "services/Dockerfile")
		svc('frontend',	'../sources/', dbtks+'{port_postfix}"', "frontend/Dockerfile")

	join_all()
	print("ok!")


if __name__ == '__main__':
	cli()







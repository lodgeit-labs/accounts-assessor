#!/usr/bin/env python3.9

import os,subprocess,time,shlex,logging,sys,threading


l = logging.getLogger()
l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())


sq = shlex.quote
ss = shlex.split



try:
	import click
	import yaml
	yaml.FullLoader
except:
	print('please install:\npython3.9 -m pip install --user -U click pyyaml')
	exit(1)



from copy import deepcopy
from urllib.parse import urlparse
	


def ccd(cmd, env):
	logging.getLogger().info(' '.join([f'{k}={(v).__repr__()} ' for k,v in env.items()]) + shlex.join(cmd))
	subprocess.check_call(cmd, env=env)


@click.group()
def cli():
	pass


@cli.command(
	help="""deploy the docker compose/stack""",
	context_settings=dict(
    	ignore_unknown_options=True
    ))

@click.option('-d1', '--debug_frontend_server', 				type=bool, 	default=False, 
	help="")

@click.option('-pp', '--port_postfix', 				type=str, 	default='', 
	help="last two or more digits of the services' public ports. Also identifies the particular docker stack.")

@click.option('-hn', '--use_host_network', 			type=bool, 	default=False, 
	help="tell docker to attach the containers to host network, rather than creating one?")

@click.option('-ms', '--mount_host_sources_dir', 	type=bool, 	default=False, 
	help="bind-mount sources, instead of copying them into the image? Useful for development.")

@click.option('-nr', '--django_noreload', 			type=bool, 	default=False, 
	help="--noreload. Disables python source file watcher-reloader (to save CPU). Prolog code is still reloaded on every server invocation (even when not bind-mounted...)")

@click.option('-pu', '--public_url', 				type=str, 	required=True,
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

@click.option('-om', '--omit_service', 'omit_services', type=str, default=[], multiple=True,
	help=" ")

@click.option('-sd', '--secrets_dir', type=str, default='../secrets/',
	help=" ")

#@click.argument('build_args', nargs=-1, type=click.UNPROCESSED)
@click.option('-nc', '--no_cache', type=str, default=[], multiple=True,	help="avoid builder cache for these images")

@click.pass_context
def run(ctx, port_postfix, public_url, parallel_build, rm_stack, **choices):
	no_cache = choices['no_cache']
	del choices['no_cache']

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

ProxyPassReverse "/clients" "http://{frontend}:7788/clients"
ProxyPass "/clients" "http://{frontend}:7788/clients"  connectiontimeout=160 timeout=160 retry=10 acquire=3000 Keepalive=Off

ProxyPassReverse "/backend" "http://{frontend}:7788/backend"
ProxyPass "/backend" "http://{frontend}:7788/backend"  connectiontimeout=160 timeout=160 retry=10 acquire=3000 Keepalive=Off

"""
	)
 
	pp = port_postfix

	if choices['mount_host_sources_dir']:
		hollow = 'hollow'
	else:
		hollow = 'full'
	
	if choices['django_noreload']:
		django_args	= " --noreload"
	else:
		django_args	= ''
	
	stack_fn = generate_stack_file(port_postfix, public_url, choices)
	if rm_stack and not compose:
		shell('docker stack rm robust' + pp)

	ctx.invoke(build,*(),**{'port_postfix':pp,'mode':hollow,'parallel':parallel_build,'no_cache':no_cache})
	#build2(**{'port_postfix':pp,'mode':hollow,'parallel':parallel_build,'no_cache':no_cache})
	#shell('./lib/build.sh -pp "'+pp+'" --mode ' + hollow + pb)

	if rm_stack:
		# wait for robust network to disappear
		while True:
			cmdxxx = "docker network ls | grep robust" + pp
			p = subprocess.run(cmdxxx, shell=True, stdout=subprocess.PIPE)
			print(cmdxxx + ': ' + str(p.returncode) + ':')
			print(p.stdout)
			if p.returncode:
				break
			time.sleep(1)
			#print('.')
	shell('./lib/git_info.fish')
	e = env={"PP": pp, 'DJANGO_ARGS':django_args, 'DISPLAY':os.environ['DISPLAY']}
	if compose:
		cmd = '/usr/local/bin/docker-compose -f ' + stack_fn + ' -p robust  --compatibility '
		import atexit
		atexit.register(lambda: ccd(ss(cmd + ' down  -t 999999 '), env=e))
		ccd(ss(cmd + ' up'), env=e)
		# --remove-orphans

	else:
		ccd(ss('docker stack deploy --prune --compose-file') + [stack_fn, 'robust'+pp], env=e)
		shell('docker stack ps robust'+pp + ' --no-trunc')
		shell('./follow_logs_noagraph.sh '+pp)


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
	with open('docker-stack.yml') as file_in:
		src = yaml.load(file_in, Loader=yaml.FullLoader)
		fn = '../generated_stack_files/docker-stack' + ('__'.join(['']+[k for k,v in choices.items() if v])) + '.yml'

	with open(fn, 'w') as file_out:
		yaml.dump(tweaked_services(src, port_postfix, PUBLIC_URL, **choices), file_out)
	return fn


def tweaked_services(src, port_postfix, PUBLIC_URL, use_host_network, mount_host_sources_dir, django_noreload, enable_public_gateway, debug_frontend_server, enable_public_insecure, compose, omit_services, secrets_dir):

	res = deepcopy(src)
	services = res['services']
	services['frontend']['environment']['PUBLIC_URL'] = PUBLIC_URL

	if debug_frontend_server:
		services['frontend']['environment']['DJANGO_SETTINGS_MODULE'] = "frontend_server.settings_dev"

	if not enable_public_gateway:
		del services['caddy']

	if enable_public_insecure and not compose:
		services['apache']['ports'] = ["88"+port_postfix+":80"]
		services['agraph']['ports'] = ["100"+port_postfix+":10035"]

	if not 'secrets' in res:
		res['secrets'] = {}
	#print(res['secrets'])
	for fn,path in files_in_dir(secrets_dir):
		if fn not in res['secrets']:
			#print (path)
			res['secrets'][fn] = {'file':(path)}
	#print(res['secrets'])

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
			if 'RABBITMQ_URL' in v['environment']:
				v['environment']['RABBITMQ_URL']='localhost:5672'

	if compose:
		del res['networks']
		for k,v in services.items():
			if 'hostnet_ports' in v:
				del v['hostnet_ports']
			v['ports'] = []
				# for port in v['hostnet_ports']:
				# 	v['ports'].append(str(port)+':'+str(port))

			del v['networks']
			if 'deploy' in v:
				del v['deploy']
			#v = v['deploy']
			#if 'update_config' in v:
			#	del v['update_config']
			#if 'restart_policy' in v:
			#	if 'delay' in v['restart_policy']:
			#		del v['restart_policy']['delay']

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

	for omit_service in omit_services:
		del services[omit_service]

		for k,v in services.items():
			if omit_service in v.get('depends_on',[]):
				v['depends_on'].remove(omit_service)


	return res


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






class ExcThread(threading.Thread):

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
			exit(1)
			new_exc = Exception(msg)
			raise new_exc.with_traceback(self.exc[2])







def co(cmd):
	return subprocess.check_output(cmd, text=True, universal_newlines=True)
def cc(cmd):
	return subprocess.check_call(cmd, text=True, universal_newlines=True, bufsize=1)

def ccss(cmd):
	return cc(ss(cmd))


threads = []


def task(cmd):
	thread = ExcThread(target = ccss, args = ('stdbuf -oL -eL ' + cmd,))
	thread.task = cmd
	threads.append(thread)
	thread.start()
	if not _parallel:
		thread.join()
	return thread


def realpath(x):
	return co(['realpath', x])[:-1]


def chdir(x):
	print(f'cd {x}')
	os.chdir(x)


@cli.command(help="""build the docker images.""")

@click.option('-pp', '--port_postfix', 				type=str, 	default='',
	help="last two or more digits of the services' public ports. Also identifies the particular docker stack.")

@click.option('-m', '--mode', 				type=str, 	default='full',
	help="hollow or full images? mount host directories containing source code or copy everything into image?")

@click.option('-p', '--parallel', 			type=bool, 	default=False,
	help="build docker images in parallel?")

@click.option('-nc', '--no_cache', type=str, default=[], multiple=True,	help="avoid builder cache for these images")


def build(**kwargs):
	try:
		build2(**kwargs)
	except subprocess.CalledProcessError as e:
		print('Sorry for the inconvenience!')
	except Exception as e:
		print(type(e))

def build2(port_postfix, mode, parallel, no_cache):
	global _parallel
	_parallel=parallel

	cc('../docker_scripts/lib/git_info.fish')

	# print()
	# print("flower...")
	# task(f'docker build -t  "koo5/flower{port_postfix}"             -f "../docker_scripts/flower/Dockerfile" . ')
	#

	chdir('../docker_scripts/')

	print()
	print("apache...")
	chdir('apache')
	task(f'docker build -t  "koo5/apache{port_postfix}"             -f "Dockerfile" . ')
	chdir('..')

	print()
	print("agraph...")
	chdir('agraph')
	task(f'docker build -t  "koo5/agraph{port_postfix}"             -f "Dockerfile" . ')
	chdir('..')

	print()
	print("super-bowl...")
	chdir('../sources/super-bowl/')
	task(f'docker build -t  "koo5/super-bowl"             -f "container/Dockerfile" . ')
	chdir('../../docker_scripts/')

	print()
	print("ubuntu...")
	chdir('ubuntu')
	task(f'docker build -t  "koo5/ubuntu" '+('--no-cache' if 'ubuntu' in no_cache else '')+' -f "Dockerfile" . ').join()
	chdir('..')


	chdir('../sources/')

	print()
	print("remoulade-api...")
	task(f'docker build -t  "koo5/remoulade-api-hlw{port_postfix}"    -f "remoulade_api/Dockerfile" . ')

	print()
	print("internal-workers-hlw...")
	task(f'docker build -t  "koo5/workers-hlw{port_postfix}"   -f "internal_workers/Dockerfile_hollow" . ')

	print()
	print("internal-services-hollow...")
	task(f'docker build -t  "koo5/services-hlw{port_postfix}"  -f "internal_services/Dockerfile_hollow" . ')

	print()
	print("frontend-server-hollow...")
	task(f'docker build -t  "koo5/frontend-hlw{port_postfix}"    -f "frontend_server/Dockerfile_hollow" . ')


	for thread in threads:
		thread.join()
	print("ok...")


	if mode == "full":
		print()
		print("internal-workers...")
		task(f'docker build -t  "koo5/workers{port_postfix}"   -f "internal_workers/Dockerfile" . ')

	if mode == "full":
		print()
		print("internal-services...")
		task(f'docker build -t  "koo5/services{port_postfix}"  -f "internal_services/Dockerfile" . ')

	if mode == "full":
		print()
		print("frontend-server...")
		task(f'docker build -t  "koo5/frontend{port_postfix}"    -f "frontend_server/Dockerfile" . ')


	for thread in threads:
		thread.join()
	print("ok!")







if __name__ == '__main__':
	cli()












## https://github.com/docker/compose/issues/3012#issuecomment-219543906

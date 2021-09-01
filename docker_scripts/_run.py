#!/usr/bin/env python3


try:
	import click
	import yaml
except:
	print('please install:\npython3.9 -m pip install --user -U click pyyaml')
	exit(1)

import os,subprocess,time,shlex
from copy import deepcopy

	

@click.command()

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

@click.option('-ph', '--public_host', 				type=str, 	default='localhost', 
	help="The public-facing hostname. Used for Caddy.")

@click.option('-pg', '--enable_public_gateway', type=bool, default=True, 
	help="enable Caddy (on ports 80 and 443). This generally does not make much sense on a development machine, because 1) you're only getting a self-signed cert that excel will refuse, 2)maybe you already have another web server listening on these ports, 3) using -pp (non-standard ports) in combination with https will give you trouble. 4) You must access the server by a hostname, not just IP.")

@click.option('-pi', '--enable_public_insecure', type=bool, default=False, 
	help="skip caddy and expose directly the apache server on port 88.")

def run(port_postfix, public_host, **choices):

	# caddy is just gonna listen on 80 and 443 always.
	generate_caddy_config(public_host)

	open('../sources/apache/conf/dynamic.conf','w').write(
f"""
ServerName {public_host}
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
	
	stack_fn = generate_stack_file(port_postfix, choices)
	shell('docker stack rm robust' + pp)
	shell('./build.sh -pp "'+pp+'" --mode ' + hollow)
	while True:
		cmdxxx = "docker network ls | grep robust" + pp
		p = subprocess.run(cmdxxx, shell=True, stdout=subprocess.PIPE)
		print(cmdxxx + ': ' + str(p.returncode) + ':')
		print(p.stdout)
		if p.returncode:
			break
		time.sleep(1)
		#print('.')
	shell('./deploy_stack.sh "'+pp+'" ' + stack_fn + ' ' + django_args)
	shell('docker stack ps robust'+pp + ' --no-trunc')
	shell('./follow_logs_noagraph.sh '+pp)


def generate_caddy_config(public_host):
	cfg = f'''

	# autogenerated by _run.py.

	{{
		debug

		#auto_https off
		#http_port  80
		#https_port 443 
		
		#admin 127.0.0.1:2019 {{
		#	origins 127.0.0.1
		#}}
	}}

	{public_host} {{
		import Caddyfile_auth
		reverse_proxy apache:80
	}}
	'''
	
	with open('../sources/caddy/Caddyfile', 'w') as f:
		f.write(cfg)    


def generate_stack_file(port_postfix, choices):
	with open('docker-stack.yml') as file_in:
		src = yaml.load(file_in, Loader=yaml.FullLoader)
		fn = '../sources/docker-stack' + ('__'.join(['']+[k for k,v in choices.items() if v])) + '.yml'
	with open(fn, 'w') as file_out:
		yaml.dump(tweaked_services(src, port_postfix, **choices), file_out)
	return fn


def tweaked_services(src, port_postfix, use_host_network, mount_host_sources_dir, django_noreload, enable_public_gateway, debug_frontend_server, enable_public_insecure):
	res = deepcopy(src)
	services = res['services']
	
	if debug_frontend_server:
		services['frontend-server']['environment']['DJANGO_SETTINGS_MODULE'] = "frontend_server.settings_dev"
	
	if not enable_public_gateway:
		del services['caddy']

	if enable_public_insecure:
		services['apache']['ports'] = ["88:80"]

	if not 'secrets' in res:
		res['secrets'] = {}
	for fn,path in files_in_dir('../secrets/'):
		if fn not in res['secrets']:
			res['secrets'][fn] = {'file':path}
	
	if use_host_network:
		for k,v in services.items():
			v['networks'] = ['hostnet']

	if mount_host_sources_dir:
		for x in ['internal-workers','internal-services','frontend-server' ]:
			if x in services:
				services[x]['volumes'].append('.:/app/sources')
				assert services[x]['image'] == f'koo5/{x}${{PP}}:latest', services[x]['image']
				services[x]['image'] = f'koo5/{x}-hollow{port_postfix}:latest'

		services['internal-workers']['volumes'].append('./swipl/xpce:/root/.config/swi-prolog/xpce')

	if 'DISPLAY' in os.environ:
		if 'internal-workers' in services:
			services['internal-workers']['environment']['DISPLAY'] = "${DISPLAY}"
		
	return res


def files_in_dir(dir):
	result = []
	for filename in os.listdir(dir):
		filename2 = os.path.join(dir, filename)
		if os.path.isfile(filename2):
			result.append((filename,filename2))
	return result


def shell(cmd):
	print('>'+cmd)
	r = os.system(cmd)
	if r != 0:
		exit(r)


if __name__ == '__main__':
    run()



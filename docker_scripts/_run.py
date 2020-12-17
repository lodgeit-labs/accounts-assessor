#!/usr/bin/env python3

try:
	import click
	import yaml
except:
	print('please install: python3 -m pip install --user -U click pyyaml')
	exit(1)

import os,subprocess,time,shlex
from copy import deepcopy

	

@click.command()
@click.option('-pp', '--port_postfix', type=str, default='88', help="last two or more digits of the services' public ports. Also identifies the particular docker stack.")
@click.option('-hn', '--use_host_network', type=bool, default=False, help="use host network?")
@click.option('-ms', '--mount_host_sources_dir', type=bool, default=False, help="bind-mount sources, instead of copying them into the image? Useful for development.")
def run(port_postfix, **choices):

	pp = port_postfix

	if choices['mount_host_sources_dir']:
		hollow = '_hollow'
	else:
		hollow = ''
	
	stack_fn = generate_stack_file(choices)
	shell('docker stack rm robust' + pp)
	shell('./build.sh "'+pp+'" ' + hollow)
	while True:
		p = subprocess.run("docker network ls | grep robust" + pp, shell=True, stdout=subprocess.PIPE)
		print(p.returncode)
		if p.returncode:
			break
		print(p.stdout)
		time.sleep(1)
		print('.')
	shell('./deploy_stack.sh "'+pp+'" ' + stack_fn)
	shell('docker stack ps robust'+pp + ' --no-trunc')
	shell('./follow_logs.sh '+pp)
	

def generate_stack_file(choices):
	with open('docker-stack.yml') as file_in:
		src = yaml.load(file_in, Loader=yaml.FullLoader)
		fn = '../sources/docker-stack' + ('__'.join(['']+[k for k,v in choices.items() if v])) + '.yml'
	with open(fn, 'w') as file_out:
		yaml.dump(tweaked_services(src, **choices), file_out)
	return fn


def tweaked_services(src, use_host_network, mount_host_sources_dir):
	res = deepcopy(src)
	services = res['services']

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


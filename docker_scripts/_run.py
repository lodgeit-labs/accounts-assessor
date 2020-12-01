#!/usr/bin/env python3

# python3 -m pip install --user -U click pyyaml

try:
	import click
	import yaml
except:
	print('please install: python3 -m pip install --user -U click pyyaml')
	exit(1)

import os
from copy import deepcopy

	

@click.command()
@click.option('-pp', '--port_postfix', type=str, default='')
@click.option('-hn', '--use_host_network', type=bool, default=False)
@click.option('-ms', '--mount_host_sources_dir', type=bool, default=False)
def run(port_postfix, **choices):

	pp = port_postfix

	if choices['mount_host_sources_dir']:
		hollow = '_hollow'
	else:
		hollow = ''
	
	stack_fn = generate_stack_file(choices)
	shell('docker stack rm robust' + pp)
	shell('./build.sh "'+pp+'" ' + hollow)
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
	if use_host_network:
		for k,v in res['services'].items():
			v['networks'] = ['hostnet']
		#res['networks'] = {'host':None}
	if mount_host_sources_dir:
		for x in ['internal-workers','internal-services','frontend-server' ]:
			services = res['services']
			if x in services:
				services[x]['volumes'].append('.:/app/sources')
		
	if not 'secrets' in res:
		res['secrets'] = {}
		
	for fn,path in files_in_dir('../secrets/'):
		if fn not in res['secrets']:
			res['secrets'][fn] = {'file':path}
		
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
		



#	for b0 in [True, False]:
#		choices['use_host_network'] = b0
#		for b1 in [True, False]:
#			choices['mount_host_sources_dir'] = b1



if __name__ == '__main__':
    run()


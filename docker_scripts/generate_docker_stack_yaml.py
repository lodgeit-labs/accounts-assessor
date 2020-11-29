#!/usr/bin/env python3.8

import yaml, os
from copy import deepcopy


def run():
	with open('docker-stack.yml') as file_in:
		src = yaml.load(file_in, Loader=yaml.FullLoader)

	choices = {}
	
	for b0 in [True, False]:
		choices['use_host_network'] = b0
		for b1 in [True, False]:
			choices['mount_host_sources_dir'] = b1
			
			fn = '../generated-docker-stacks/docker-stack' + ('__'.join(['']+[k for k,v in choices.items() if v])) + '.yml'
			with open(fn, 'w') as file_out:
				yaml.dump(tweaked_services(src, **choices), file_out)
		

def tweaked_services(src, use_host_network, mount_host_sources_dir):
	res = deepcopy(src)
	if use_host_network:
		for k,v in res['services'].items():
			v['networks'] = ['host']
		res['networks'] = {'host':None}
	if mount_host_sources_dir:
		res['services']['internal-workers' ]['volumes'].append('.:/app/sources')
		res['services']['internal-services']['volumes'].append('.:/app/sources')
		res['services']['frontend-server'  ]['volumes'].append('.:/app/sources')
		
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


if __name__ == '__main__':
    run()


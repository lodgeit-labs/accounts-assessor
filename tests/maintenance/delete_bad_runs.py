#!/usr/bin/env python3

import json, sys, os
import pathlib
import shutil
import fire


def run(session = '~/robust_tests/latest'):
	dir = pathlib.Path(os.path.expanduser(session))
			
	summary = dir/'summary.json'
	with open(summary) as f:
		j = json.load(f)

	bad = j['bad']
	
	print(len(bad))
	#print(len([x for x in bad if x['job'] == 502]))
	
	for i in bad:
		print(i)

	print(f'delete {len(bad)} tests')
	for i in bad:
 		shutil.rmtree(i['test']['path'], onerror=lambda _x,x,_xx: print(f'error deleting {x}'))
		
	print(f'delete {summary}')
	summary.unlink(missing_ok=True)
	



if __name__ == '__main__':
	fire.Fire(run)
	
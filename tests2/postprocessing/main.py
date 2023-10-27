#!/usr/bin/env python3

import json, sys
import pathlib
import shutil

if __name__ == '__main__':
	
	dir = pathlib.PurePath(sys.argv[1])
			
	with open(dir/'summary.json') as f:
		j = json.load(f)

	bad = j['bad']
	
	print(len(bad))
	#print(len([x for x in bad if x['job'] == 502]))
	
	for i in bad:
		print(i)

	# print(f'delete {len(bad)} tests')
	# for i in bad:
	# 	try:
	# 		shutil.rmtree(i['test']['path'])
	# 	except:
	# 		pass
	# 	
	# 
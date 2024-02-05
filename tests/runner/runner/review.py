import json
import os
import subprocess

summary = os.path.expanduser('robust_tests/latest/summary.json')

with open(summary) as f:
	j = json.load(f)
	for case in j['bad']:
		print(case['test']['dir'])
		
		for d in case['delta']:
			print(d['msg'])
			
			if d['msg'] == "job.json is missing in testcase":
				
				fix = d['fix']
				subprocess.check_call([fix['op'], fix['src'], fix['dst']], shell=True)
		
		print()
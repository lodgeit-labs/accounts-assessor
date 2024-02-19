#!/usr/bin/env python3
import sys,os
import time
import subprocess
import click,json
from common import robust_tests_folder
#import PyInquirer



def prompt(*args, **kwargs):
	return PyInquirer.prompt(*args, **kwargs)


def verbalize_fix(f):
	return f['op'] + ' ' + f['src'] + ' ' + f['dst']


@click.command()
def main():
	
	summary = robust_tests_folder() + '/latest/summary.json'
	
	with open(summary) as f:
		j = json.load(f)
	
	# for case in j['bad']:
	# 	print(case['test']['dir'])
	# 
	# 	for d in case['delta']:
	# 		print(d['msg'])
	# 		
	# 		if d['msg'] == "job.json is missing in testcase":
	# 
	# 			fix = d['fix']
	# 			#print(prompt(verbalize_fix(fix) + '?'))
	# 			print(verbalize_fix(fix) + '?')
	# 			run_fix(fix)


	for case in j['evaluations']:
		print(case['test']['dir'])
		print(case['job']['result']['alerts'])



def run_fix(fix):
	if fix['op'] == 'cp':
		subprocess.check_call(['cp', fix['src'], fix['dst']])
	else:
		print('unknown op')



if __name__ == '__main__':
	main()



# def dirs_fixup():
# 	"""walk testcase dirs and do some stuff"""
# 	suite = P('../../tests2/endpoint_tests/')
# 	for d in robust_testcase_dirs(suite):
# 		print(f'testcase:{d}')
# 		newdir = str(suite / d / 'request')
# 		print(f'newdir: {newdir}')
# 		makedirs(newdir, exist_ok=True)
# 		for file in listfiles(suite / d):
# 			print(f'request file:{file}')
# 			tgt = str(suite / d / 'request' / os.path.basename(file))
# 			print(f'tgt:{tgt}')
# 			os.rename(file, tgt)

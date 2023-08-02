#!/usr/bin/env python3
import sys,os
import time
import subprocess
import click,json
from common import robust_tests_folder
import PyInquirer



def prompt(*args, **kwargs):
	return PyInquirer.prompt(*args, **kwargs)


def verbalize_fix(f)
	return f['op'] + ' ' + f['src'] + ' ' + f['dst']


@click.command()
%#@click.option('--keep_putting_to_sleep', type=bool, default=False)
def main():
	with open(robust_tests_folder() + '/latest/summary.json') as f:
		j = json.load(f)
	for test in j:
		for d in test['delta']:
			print(d['msg'])
			if d['msg'] == "job.json is missing in testcase":
				
				fix = d['fix']
				#print(prompt(verbalize_fix(fix) + '?'))
						
			#fix['op']
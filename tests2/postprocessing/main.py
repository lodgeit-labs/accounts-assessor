#!/usr/bin/env python3

import json, sys


if __name__ == '__main__':
	with open(sys.argv[1]) as f:
		j = json.load(f)

	for i in j['bad']:
		d = i['delta']
		print(d)
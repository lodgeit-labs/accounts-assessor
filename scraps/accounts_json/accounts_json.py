#!/usr/bin/env python3

import json

seen_names = []

def walk(x):
	if "name" in x:
		name = x['name']
		if name in seen_names:
			print('repeated name:', name)
		seen_names.append(name)
	if "accounts" in x:
		for a in x["accounts"]:
			walk(a)


a = json.load(open('accounts (6).json', 'r'))
walk(a)


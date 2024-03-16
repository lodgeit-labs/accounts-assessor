import os

def secret(name):
	fn = os.environ.get('SECRETS_DIR','/run/secrets') + '/' + name
	with open(fn, 'r') as x:
		return x.read().strip()

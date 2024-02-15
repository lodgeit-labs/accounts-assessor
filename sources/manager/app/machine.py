import os
fly = os.environ.get('FLY', False)

def list_machines():
	if fly:
		return json.loads(subprocess.check_output('flyctl machines list --json', shell=True))
		#return requests.get('https://api.fly.io/v6/apps/robust/instances').json()
	else:
		raise Exception('FLY not enabled')

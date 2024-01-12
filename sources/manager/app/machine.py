fly = False

def list_machines():
	if fly:
		return requests.get('https://api.fly.io/v6/apps/robust/instances').json()
	else:
		return []

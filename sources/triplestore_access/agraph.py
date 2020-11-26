import json, os

def secrets():
	with open(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../../secrets2.json')), 'r') as s2:
		return json.load(s2)


def env_or(json, key):
	#print(key, '=', os.environ.get(key), ' or ', json.get(key))
	return os.environ.get(key) or json.get(key)

def agc():
	#from franz.openrdf.repository.repository import Repository
	# from franz.openrdf.sail.allegrographserver import AllegroGraphServer

	agraph_secrets = secrets()
	#print(os.environ)
	AGRAPH_SECRET_HOST = env_or(agraph_secrets, 'AGRAPH_SECRET_HOST')
	AGRAPH_SECRET_PORT = env_or(agraph_secrets, 'AGRAPH_SECRET_PORT')
	AGRAPH_SECRET_USER = env_or(agraph_secrets, 'AGRAPH_SECRET_USER')
	AGRAPH_SECRET_PASSWORD = env_or(agraph_secrets, 'AGRAPH_SECRET_PASSWORD')
	del agraph_secrets

	if AGRAPH_SECRET_USER != None and AGRAPH_SECRET_PASSWORD != None:
		from franz.openrdf.connect import ag_connect
		#print(f"""ag_connect('a', host={AGRAPH_SECRET_HOST}, port={AGRAPH_SECRET_PORT}, user={AGRAPH_SECRET_USER},password={AGRAPH_SECRET_PASSWORD})""")
		return ag_connect('a', host=AGRAPH_SECRET_HOST, port=AGRAPH_SECRET_PORT, user=AGRAPH_SECRET_USER, password=AGRAPH_SECRET_PASSWORD)
	else:
		print('agraph user and pass must be provided')
		exit(1)

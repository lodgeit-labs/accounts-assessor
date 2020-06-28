import json, os

def secrets():
	with open(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../secrets2.json')), 'r') as s2:
		return json.load(s2)

def agc():
	#from franz.openrdf.repository.repository import Repository
	# from franz.openrdf.sail.allegrographserver import AllegroGraphServer

	agraph_secrets = secrets()
	AGRAPH_SECRET_HOST = agraph_secrets.get('AGRAPH_SECRET_HOST')
	AGRAPH_SECRET_PORT = agraph_secrets.get('AGRAPH_SECRET_PORT')
	AGRAPH_SECRET_USER = agraph_secrets.get('AGRAPH_SECRET_USER')
	AGRAPH_SECRET_PASSWORD = agraph_secrets.get('AGRAPH_SECRET_PASSWORD')
	del agraph_secrets

	if AGRAPH_SECRET_USER != None and AGRAPH_SECRET_PASSWORD != None:
		from franz.openrdf.connect import ag_connect
		return ag_connect('a', host=AGRAPH_SECRET_HOST, port=AGRAPH_SECRET_PORT, user=AGRAPH_SECRET_USER, password=AGRAPH_SECRET_PASSWORD)
	else:
		print('agraph user and pass not provided, skipping')

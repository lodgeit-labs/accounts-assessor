





app = FastAPI(
	title="Robust worker private prolog facing helper api"
)

def manager_proxy_thread():
	while True:
		r = requests.post(os.environ['MANAGER_URL'] + '/messages', json=dict(org=org, id=id, procs=['call_prolog', 'arelle', 'download']))
		r.raise_for_status()
		msg = r.json()

		if msg['type'] == 'job':
			if msg['proc'] == 'call_prolog':
				return call_prolog(msg['msg'], msg['options'])
			elif msg['proc'] == 'arelle':
				return arelle(msg['msg'], msg['options'])
			elif msg['proc'] == 'download':
				return download(msg['msg'], msg['options'])
			else:
				raise Exception('unknown proc: ' + msg['proc'])


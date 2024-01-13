
app = FastAPI(
	title="Robust worker private api"
)

client_id = subprocess.check_output(['hostname'], text=True).strip() + '-' + str(os.getpid())
def manager_proxy_thread():
	while True:
		r = requests.post(os.environ['MANAGER_URL'] + '/messages', json=dict(id=client_id, procs=['call_prolog', 'arelle', 'download']))
		r.raise_for_status()
		msg = r.json()

		if msg['type'] == 'job':
			if msg['proc'] == 'call_prolog':
				return call_prolog(msg['msg'], msg['worker_options'])
			elif msg['proc'] == 'arelle':
				return arelle(msg['msg'], msg['worker_options'])
#			elif msg['proc'] == 'download':
#				return download(msg['msg'], msg['worker_options'])
#				safely covered by download_bastion i think
			else:
				raise Exception('unknown proc: ' + msg['proc'])



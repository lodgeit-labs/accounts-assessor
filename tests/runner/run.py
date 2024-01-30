#!/usr/bin/env python3
import requests
import subprocess. click, logging, sys, os, time, threading, json
log = logging.getLogger(__name__)

def co(x):
	return subprocess.check_output(x, shell=True)

@click.command()
@click.option('--server', required=True, default='http://localhost:8877')
def run(server):
	
	
	os.cwd(os.path.dirname(__file__))
	if os.path.exists('venv'):
		pass
	else:
		co('./init_venv.sh')
	




	r = requests.post(server + '/chat/', json=dict(
		{
			"method": "chat",
			"params": {"type":"sbe","current_state":[]}
		}
	))
	r.raise_for_status()
	r = r.json()
	
	if r != {"result":{"question":"Are you a Sole trader, Partnership, Company or Trust?","state":[{"question_id":0,"response":-1}]}}:
		log.error('bad response: %s', r)
		sys.exit(1)
	



	
	r = json.loads(co("""curl -X 'GET' \
  server + '/ai3/div7a?loan_year=2020&full_term=7&opening_balance=100000&opening_balance_year=2020&lodgement_date=2021-06-30&repayment_dates=2021-06-30&repayment_dates=2022-06-30&repayment_dates=2023-06-30&repayment_amounts=10001&repayment_amounts=10002&repayment_amounts=10003' -H 'accept: application/json'"""))

	del r['details_url']

	if r == {}:
		pass
	else:
		log.error('bad response: %s', r)
		sys.exit(1)


	
	
	
	# this still requires scheduler server and helper workers to be running
	# ./luigi_scheduler_server.sh
	# ./luigi_worke.sh

	co(f'PYTHONPATH=(pwd) luigi --module runner.tests2 --Permutations-robust-server-url {server} --Permutations-suite ../endpoint_tests/ --workers=30 Summary')

	"""
	evaluation is required here.
	we should either run the worker through python here, 
	or come up with session name,
	and then check the results.
	"""
	#log.info('ok.')

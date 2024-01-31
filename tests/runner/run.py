#!/usr/bin/env python3
import requests
import subprocess, click, logging, sys, os, time, threading, json
log = logging.getLogger(__name__)

def co(x):
	log.info(x)
	return subprocess.check_output(x, shell=True)

@click.command()
@click.option('--server', required=True, default='http://localhost:8877')
def run(server):


	logging.basicConfig(level=logging.INFO)
	
	os.chdir(os.path.dirname(__file__))
	if os.path.exists('venv'):
		pass
	else:
		co('./init_venv.sh')
	




	r = requests.post(server + '/chat/', json=dict(
		{"type":"sbe","current_state":[]}
	))
	r.raise_for_status()
	r = r.json()
	
	if r != {"result":{"question":"Are you a Sole trader, Partnership, Company or Trust?","state":[{"question_id":0,"response":-1}]}}:
		log.critical('bad response: %s', r)
		sys.exit(1)
	log.info('ok..')



	
	r = json.loads(co(f"""curl -X 'GET' '{server}/ai3/div7a?loan_year=2020&full_term=7&opening_balance=100000&opening_balance_year=2020&lodgement_date=2021-06-30&repayment_dates=2021-06-30&repayment_dates=2022-06-30&repayment_dates=2023-06-30&repayment_amounts=10001&repayment_amounts=10002&repayment_amounts=10003' -H 'accept: application/json'"""))

	del r['details_url']

	if r == {'2020': {'events': [{'type': 'loan created', 'date': '2020-06-30', 'loan_principal': 100000.0, 'loan_term': 7}]}, '2021': {'events': [{'type': 'repayment', 'date': '2021-06-30', 'amount': 10001.0}, {'type': 'lodgement', 'date': '2021-06-30'}, {'date': '2021-06-30', 'type': 'end', 'note': 'This concludes the calculation. Calculation for subsequent years is not possible because the minimum yearly repayment was not met in this year.'}], 'opening_balance': 100000.0, 'minimum_yearly_repayment': 16982.569493922907, 'total_repaid': 10001.0, 'repayment_shortfall': 6981.569493922907, 'interest_rate': 4.52, 'total_interest_accrued': 4518.76152, 'total_principal_paid': 5482.23848, 'closing_balance': 94517.76152}}:
		pass
	else:
		log.error('bad response: %s', r)
		sys.exit(1)
	log.info('ok..')

	
	
	
	# this still requires scheduler server and helper workers to be running
	# ./luigi_scheduler_server.sh
	# ./luigi_worke.sh

	#co(f'PYTHONPATH=(pwd) luigi --module runner.tests2 --Permutations-robust-server-url {server} --Permutations-suite ../endpoint_tests/ --workers=30 Summary')

	"""
	evaluation is required here.
	we should either run the worker through python here, 
	or come up with session name,
	and then check the results.
	"""
	#log.info('ok.')


if __name__ == '__main__':
	run()
import logging
import os
import subprocess
import threading
import time
from app.isolated_worker import *
from config import secret



log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
#log.addHandler(logging.StreamHandler(sys.stderr))
log.debug("debug machine.py")



server_started_time = datetime.datetime.now()
fly_machines = {}



def flyctl():
	#os.system('pwd')
	#os.system('which flyctl')
	return '/home/myuser/.fly/bin/flyctl -t "'+ secret('FLYCTL_API_TOKEN') + '" '



def list_machines():
	r = sorted(json.loads(subprocess.check_output(f'{flyctl()} machines list --json', shell=True)), key=lambda x: x['id'])
	for machine in r:
		machine['created_at'] = datetime.datetime.strptime(machine['created_at'], '%Y-%m-%dT%H:%M:%SZ')
	
		machine['worker'] = None
		for _,worker in workers.items():
			if worker.info.get('host') == machine['id']:
				machine['worker'] = worker
	
	return r



def start_machine(machine):
	cmd = f'{flyctl()} machines start {machine["id"]}'
	log.debug(cmd)
	subprocess.run(cmd, shell=True)
	fly_machines[machine['id']] = dict(started=datetime.datetime.now(), machine=machine)



def stop_machine(machine):
	cmd = f'{flyctl()} machines stop {machine["id"]}'
	log.debug(cmd)
	subprocess.run(cmd, shell=True)




def fly_machine_janitor():
	while True:
		try:
			log.debug(f'{len(pending_tasks)=}')
			for v in pending_tasks:
				log.debug('task %s', v)

			log.debug(f'{len(workers)=} :>')
			for _,v in workers.items():
				log.debug('worker %s', v)
		
			machines = prune_machines()

			started_machines = len([m for m in machines if m['state'] not in ['stopped']])
			active_tasks = sum(1 for _,worker in workers.items() if worker.task)
			num_tasks = len(pending_tasks) + active_tasks

			log.debug(f'fly_machine_janitor: {len(pending_tasks)=}, {active_tasks=}, num_tasks={num_tasks}, started_machines={started_machines}')

			if num_tasks > started_machines:
				log.debug('looking for machines to start')
				for machine in machines:
					if machine['state'] not in ['started', 'starting']:
						start_machine(machine)
						break

			elif num_tasks < started_machines:
				log.debug('looking for machines to stop')
				for machine in machines:
					worker = machine['worker']
					log.debug(f'{machine["id"]} {machine["state"]}, {worker=}')
					if machine['state'] in ['running', 'started'] and worker and not worker.task:
						stop_machine(machine)
						break
		
		except Exception as e:
			log.exception(e)
		
		time.sleep(10)



def prune_machines():
	pruned = False
	machines = list_machines()
	if datetime.datetime.now() - server_started_time < datetime.timedelta(minutes=1):
		return machines
					
	for machine in machines:
		if not machine['worker'] and machine['state'] not in ['stopped']:
			if machine['id'] not in fly_machines:
				stop_machine(machine)
				pruned = True
				continue
			
			started = fly_machines[machine['id']].get('started', None)
			if started is None or datetime.datetime.now() - started > datetime.timedelta(minutes=3):
				stop_machine(machine)
				pruned = True
				continue
						
	if pruned:
		return list_machines()
	return machines



if fly:
	threading.Thread(target=fly_machine_janitor, daemon=True).start()


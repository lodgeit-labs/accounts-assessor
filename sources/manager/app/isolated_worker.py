import os, sys, subprocess, json
import threading, logging
from collections import defaultdict
from dotdict import Dotdict
import datetime
import time

from app.untrusted_task import *
from app.fly_machines import *

from contextlib import contextmanager
shutdown_event = threading.Event()

import tsasync



log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
#log.addHandler(logging.StreamHandler(sys.stderr))
log.debug("debug isolated_worker.py")



fly = os.environ.get('FLY', False) == 'True'
log.info(f'{fly=}')
workers = {}
pending_tasks = []
heartbeat_interval = 10

workers_lock = threading.Lock()
workers_lock_msg = None

fly_machines_lock = threading.Lock()
fly_machines_lock_msg = None



class Worker:
	def __init__(self, id):
		self.id = id
		self.sizes = [None]
		self.info = {}
		self._task = None
		self.handler_wakeup = tsasync.Event()

		self.last_reported_task_ts = None
		self.last_reported_task = None
		self.task_given_ts = None

		self.fly_machine = None

	@property
	def task(self):
		return self._task
	@task.setter
	def task(self, task):
		self._task = task
		if task:
			self.handler_wakeup.set()
		else:
			self.handler_wakeup.clear()


	@property
	def task_id(self):
		return self.task.id if self.task else None

	def alive(self):
		return self.last_seen > datetime.datetime.now() - datetime.timedelta(seconds=10+heartbeat_interval)

	def __str__(self):
		return f'Worker({self.id}, sizes:{self.sizes}, task:{self.task_id})'

	def __repr__(self):
		return f'Worker({self.id}, sizes:{self.sizes}, task:{self.task_id})'



@contextmanager
def wl(message):
	global workers_lock_msg
	try:
		while True:
			if workers_lock_msg:
				logging.getLogger('workers_lock').debug('wl wait on: %s', workers_lock_msg)
			if workers_lock.acquire(timeout=10):
				break
	
		workers_lock_msg = message
		yield
	finally:
		logging.getLogger('workers_lock').debug('wl release from: %s', message)
		workers_lock_msg = None
		workers_lock.release()



@contextmanager
def fl(message):
	global fly_machines_lock_msg
	try:
		while True:
			if fly_machines_lock_msg:
				logging.getLogger('fly_machines_lock').debug('wl wait on: %s', fly_machines_lock_msg)
			if fly_machines_lock.acquire(timeout=10):
				break
	
		fly_machines_lock_msg = message
		yield
	finally:
		logging.getLogger('fly_machines_lock').debug('wl release from: %s', message)
		fly_machines_lock_msg = None
		fly_machines_lock.release()




def get_worker(id, last_seen=None):
	""" runs in FastAPI thread. Only place where Worker is constructed """
	with wl('get_worker'): 
		worker = workers.get(id)
		if worker is None:
			worker = Worker(id)
			workers[id] = worker
		if last_seen:
			worker.last_seen = last_seen
		#log.debug('get_worker: workers: %s', workers)
		return worker



def heartbeat(worker):
	with wl('heartbeat'):
		log.debug('thump %s', worker)
		worker.last_seen = datetime.datetime.now()



def worker_janitor():

	while True:
		with wl('worker_janitor'):
			for _,worker in workers.items():
				unseen = datetime.datetime.now() - worker.last_seen

				if not worker.task:
					# no task, so we just purge this dummy item from the list
					if unseen > datetime.timedelta(seconds=heartbeat_interval + 100):
						put_event(dict(type='forget_worker', worker=worker))
				else:
					# however, if worker has a task, we should give a configurable grace period for it to report back with result, in some cases, even after prolonged period of disconnection.
					if unseen > datetime.timedelta(seconds=heartbeat_interval + os.environ.get('WORKER_GRACE_PERIOD', 30)):
						put_event(dict(type='forget_worker', worker=worker))

		time.sleep(15)

threading.Thread(target=worker_janitor, daemon=True).start()



class MaxSizeList(list):
    def __init__(self, maxlen):
        self._maxlen = maxlen

    def append(self, element):
        self.__delitem__(slice(0, len(self) == self._maxlen))
        super(MaxSizeList, self).append(element)

results_of_unknown_tasks = MaxSizeList(1000)


def synchronization_thread():
	try:
		while not shutdown_event.is_set():

			e = Dotdict(events.get())
			log.debug('synchronization_thread: %s', e)

			with wl('synchronization_thread'):

				if e.type == 'nop':
					pass

				if e.type == 'add_task':
					for r in results_of_unknown_tasks:
						if r['task_id'] == e.task.id:
							log.debug('add_task: result already in results_of_unknown_tasks. precognition!')
							e.task.results.put(dict(result=r['result']))
							results_of_unknown_tasks.remove(r)
							break
					else:
					
						# meh, this is just wrong with fly machines. do_task needs to manage its own machine, as originally planned.
						if not fly and try_assign_any_worker_to_task(e.task, sorted_workers()):
							pass
						else:
							log.debug(f'pending_tasks.append({e.task})')
							pending_tasks.append(e.task)

				elif e.type == 'forget_worker':
					if e.worker.task:
						# raise exception in do_untrusted_task
						e.worker.task.results.put(dict(error='lost connection to worker'))
					del workers[e.worker.id]
					#if e.worker.fly_machine:
					#	e.worker.fly_machine.delete()

				elif e.type == 'worker_available':
					find_new_task_for_worker(e.worker)

				else :
					log.warn('unknown event type: %s', e.type)

	except Exception as e:
		msg = f'synchronization_thread: exception {e}'
		log.exception(msg)
		sys.exit(msg)


def on_task_result(worker, result):
	with wl('synchronization_thread'):

		if 'task_id' not in result:
			r = dict(error='task_result: no task_id in result')
			log.warn(r)
			return r
		
		if 'result' not in result:
			r = dict(error='task_result: no actual result in worker result message')
			log.warn(r)
			return r

		if result['task_id'] == worker.task_id:
			log.debug('task_result: worker %s got result for task %s', worker.id, result['task_id'])
			worker.task.results.put(dict(result=result['result']))
		else:
			log.warn('task_result: unknown task. Maybe manager restarted and does not remember giving this task to this worker.')
			# we can't trust untrusted workers with random task results, but with trusted workers we can. So we should probably have a separate list of unpaired task results, and check it in add_task
			for r in results_of_unknown_tasks:
				if r['task_id'] == result['task_id']:
					break
			else:
				results_of_unknown_tasks.append(result)

		worker.task = None
		find_new_task_for_worker(worker)

		return dict(result_ack=True)


def sorted_workers():
	return sorted(workers.values(), key=lambda w: w.last_seen, reverse=True)


def find_new_task_for_worker(worker):
	log.debug('find_new_task_for_worker: %s', worker)
	if not worker.alive():
		log.debug('find_new_task_for_worker: worker not alive')
		return
	log.debug('find_new_task_for_worker: len(pending_tasks)=%s', len(pending_tasks))
	for task in pending_tasks:
		if try_assign_worker_to_task(worker, task):
			return True


def match_worker_to_task(worker, task):
	if worker.task:
		return False
	if not worker.alive():
		return False
	return True#task.min_worker_available_mem <= worker.available_mem


def try_assign_any_worker_to_task(task, workers):
	log.debug('try_assign_any_worker_to_task: len(workers)=%s', len(workers))
	
	sw = [worker for worker in workers if not worker.task and worker.alive()]
	
	host_cores = {}
	for worker in sw:
		host_cores[worker.info.get('host')] = worker.info.get('host_cores')
		
	used_cores = defaultdict(int)
	for worker in workers:
		if worker.task:
			used_cores[worker.info.get('host')] += 1
	
	# prefer the worker on the host with the largest (cores / used_cores) ratio
	sw = sorted(sw, key=lambda w: host_cores[w.info.get('host')] / used_cores.get(w.info.get('host'),1))
				
	for worker in sw:
		if try_assign_worker_to_task(worker, task):
			return True


def try_assign_worker_to_task(worker, task):
	log.debug('try_assign_worker_to_task: %s, %s', worker, task)
	if match_worker_to_task(worker, task):
		assign_worker_to_task(worker, task)
		return True


def assign_worker_to_task(worker, task):
	log.debug('assign_worker_to_task: %s, %s', worker, task)
	worker.task = task
	if task in pending_tasks:
		pending_tasks.remove(task)





def fly_machine_janitor():
	while True:
		try:
			with wl('fly_machine_janitor'):
				with fl('fly_machine_janitor'):
					log.debug(f'{len(pending_tasks)=}')
					for v in pending_tasks:
						log.debug('task %s', v)
	
					log.debug(f'{len(workers)=}:')
					for _,v in workers.items():
						log.debug('worker %s', v)
	
					machines = fly_machines.values()
	
					started_machines = [m for m in machines if m['state'] not in ['stopped']]
	
					fly_workers = [m['worker'] for m in started_machines]
	
					for task in pending_tasks:
						try_assign_any_worker_to_task(task, fly_workers)
	
					active_tasks = sum(1 for _,worker in workers.items() if worker.task)
					num_tasks = len(pending_tasks) + active_tasks
					num_started_machines = len(started_machines)
	
					log.debug(f'fly_machine_janitor: {len(pending_tasks)=}, {active_tasks=}, num_tasks={num_tasks}, num_started_machines={num_started_machines}')
	
					# this bit needs to be enhanced if we want to support multiple sizes of workers:
					# for task in pending_tasks, if there are no free machines of right size, we should start a new machine of that size.
					# it should also be enhanced to pre-assign tasks to machines, so that we can be starting more than one machine at a time.
					if num_tasks > num_started_machines:
						log.debug('looking for machines to start')
						for machine in machines:
							if machine['state'] not in ['started', 'starting']:
								start_machine(machine)
								break
	
					log.debug('looking for machines to stop')
					for machine in machines:
						worker = machine['worker']
						log.debug(f'{machine["id"]} {machine["state"]}, {worker=}')
						if machine['state'] in ['started']:
							# never stop a machine with a task
							if worker and not worker.task:
								stop_machine(machine)
								break
							elif not worker:
								# give the machine some time to register with manager
								if datetime.datetime.now() - server_started_time > datetime.timedelta(minutes=1):
									# we didnt start it, maybe previous instance of manager started it, or it was started on fly deploy or manually..
									if machine['id'] not in fly_machines:
										stop_machine(machine)
										break
									# we started it, and it's not registering with manager
									started = fly_machines[machine['id']].get('started', None)
									if started is None or datetime.datetime.now() - started > datetime.timedelta(minutes=3):
										stop_machine(machine)
										break

		except Exception as e:
			log.exception(e)

		time.sleep(10)




if fly:
	threading.Thread(target=fly_machine_janitor, daemon=True).start()




def list_machines():
	while True:
		with fl('fly_machine_janitor'):
			r = sorted(json.loads(subprocess.check_output(f'{flyctl()} machines list --json', shell=True)), key=lambda x: x['id'])
			for machine in r:
				#machine['created_at'] = datetime.datetime.strptime(machine['created_at'], '%Y-%m-%dT%H:%M:%SZ')
				machine['worker'] = None
				for _,worker in workers.items():
					if worker.info.get('host') == machine['id']:
						machine['worker'] = worker
		
			fly_machines.clear()
			for machine in r:
				fly_machines[machine['id']] = {}
				fly_machines[machine['id']].update(machine)
	

if fly:
	threading.Thread(target=list_machines, daemon=True).start()






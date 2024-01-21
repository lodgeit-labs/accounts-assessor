import threading, logging

from dotdict import Dotdict

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.addHandler(logging.StreamHandler())

import datetime
import time

from app.machine import list_machines
from app.untrusted_task import *

from contextlib import contextmanager



workers = {}
print(id(workers))
workers_lock = threading.Lock()
workers_lock_msg = None
pending_tasks = []



class Worker:
	def __init__(self, id):
		self.id = id
		self.sizes = [None]
		self.task = None

		self.last_reported_task_ts = None
		self.last_reported_task = None
		self.task_given_ts = None

		self.fly_machine = None


	@property
	def task_id(self):
		return self.task.id if self.task else None

	def alive(self):
		return self.last_seen > datetime.datetime.now() - datetime.timedelta(minutes=2)

	def __str__(self):
		return f'Worker({self.id}, sizes:{self.sizes}, task:{self.task_id})'

	def __repr__(self):
		return f'Worker({self.id}, sizes:{self.sizes}, task:{self.task_id})'



@contextmanager
def wl(message):
	global workers_lock_msg
	try:
		if workers_lock_msg:
			logging.getLogger('workers_lock').debug('wl wait on: %s', self.wlk)
		workers_lock_msg = message
		workers_lock.acquire()
		yield
	finally:
		workers_lock.release()
		workers_lock_msg = None
		logging.getLogger('workers_lock').debug('wl release from: %s', message)



def get_worker(id, last_seen=None):
	""" runs in FastAPI thread. Only place where Worker is constructed """
	with wl('get_worker'): 
		worker = workers.get(id)
		if worker is None:
			worker = Worker(id)
			workers[id] = worker
		if last_seen:
			worker.last_seen = last_seen
		log.debug('get_worker: workers: %s', workers)
		return worker



def heartbeat(worker):
	with wl('heartbeat'):
		log.debug('thump')
		worker.last_seen = datetime.datetime.now()



def worker_janitor():
	while True:
		with wl('worker_janitor'):
			for _,worker in workers.items():
				if not worker.alive():
					if worker.task:
						put_event(dict(type='task_result', worker=worker, result=dict(
							result=dict(error='worker died'),
							task_id=worker.task.id
						)))
					put_event(dict(type='worker_died', worker=worker))
		time.sleep(10)

threading.Thread(target=worker_janitor, daemon=True).start()



def fly_machine_janitor():
	if fly:
		while True:
			with wl('fly_machine_janitor'):
				for machine in list_machines():
					for _,worker in workers.items():
						if worker.fly_machine.id == machine.id:
							break
					else:
						machine.delete()			
			time.sleep(60)
1
threading.Thread(target=fly_machine_janitor, daemon=True).start()

results_of_unknown_tasks = []

def synchronization_thread():
	while True:
	
		e = Dotdict(events.get())
		log.debug('synchronization_thread: %s', e)

		with wl('synchronization_thread'):

			if e.type == 'add_task':
				for r in results_of_unknown_tasks:
					if r.task_id == e.task.id:
						log.debug('add_task: result already in results_of_unknown_tasks. precognition!')
						e.task.results.put(dict(result=r.result))
						results_of_unknown_tasks.remove(r)
						break
				else:
					if try_assign_any_worker_to_task(e.task):
						pass
					else:
						log.debug(f'pending_tasks.append({e.task})')
						pending_tasks.append(e.task)
		
			elif e.type == 'task_result':
				if e.result.task_id == e.worker.task_id:
					e.worker.task.results.put(dict(result=e.result.result))
					e.worker.task = None
					find_new_task_for_worker(e.worker)
				else:
					log.warn('task_result: unknown task. Maybe manager restarted and does not remember giving this task to this worker.')
					# we can't trust untrusted workers with random task results, but with trusted workers we can. So we should probably have a separate list of unpaired task results, and check it in add_task
					results_of_unknown_tasks.append(e.result)

			elif e.type == 'worker_died':
					del workers[e.worker.id]
					if e.worker.fly_machine:
						e.worker.fly_machine.delete()

			elif e.type == 'worker_available':
				find_new_task_for_worker(e.worker)


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
	return True#task.min_worker_available_mem <= worker.available_mem


def try_assign_any_worker_to_task(task):
	log.debug('try_assign_any_worker_to_task: len(workers)=%s', len(workers))
	for worker in sorted_workers():
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

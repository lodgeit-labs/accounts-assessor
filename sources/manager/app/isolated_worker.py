import threading, logging

from dotdict import Dotdict

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.addHandler(logging.StreamHandler())

import datetime
import time

from app.machine import list_machines
from app.untrusted_task import *


class Worker:
	def __init__(self, id):
		self.id = id
		self.sizes = [None]
		self.task = None
		self.last_reported_task_ts = None
		self.last_reported_task = None
		self.fly_machine = None
	def alive(self):
		return self.last_seen > datetime.datetime.now() - datetime.timedelta(minutes=2)
		

workers = {}
workers_lock = threading.Lock()
pending_tasks = []



def get_worker(id, last_seen=None):
	""" runs in FastAPI thread. Only place where Worker is constructed """
	workers_lock.acquire()
	worker = workers.get(id)
	if worker is None:
		worker = Worker(id)
		workers[id] = worker
	if last_seen:
		worker.last_seen = last_seen
	workers_lock.release()
	return worker


def heartbeat(worker):
	workers_lock.acquire()
	worker.last_seen = datetime.datetime.now()
	workers_lock.release()



def worker_janitor():
	while True:
		workers_lock.acquire()
		for _,worker in workers.items():
			if not worker.alive():
				if worker.task:
					put_event(dict(type='task_result', worker=worker, result=dict(
						result=dict(error='worker died'),
						task_id=worker.task.task_id
					)))
				put_event(dict(type='worker_died', worker=worker))
				
		workers_lock.release()
		time.sleep(10)

threading.Thread(target=worker_janitor, daemon=True).start()



def fly_machine_janitor():
	if fly:
		while True:
			for machine in list_machines():
				for _,worker in workers.items():
					if worker.fly_machine.id == machine.id:
						break
				else:
					machine.delete()
			time.sleep(60)
			
threading.Thread(target=fly_machine_janitor, daemon=True).start()
		

def synchronization_thread():
	while True:
	
		e = Dotdict(events.get())
		log.debug('synchronization_thread: %s', e)
		
		workers_lock.acquire()

		if e.type == 'add_task':
			sort_workers()
			if try_assign_any_worker_to_task(e.task):
				pass
			else:
				pending_tasks.append(e.task)
	
		if e.type == 'task_result':
			if e.worker.task:
				if e.result.task_id == e.worker.task.task_id:
					e.worker.task.results.put(dict(result=e.result.result))
				e.worker.task = None
				find_new_task_for_worker(e.worker)

		if e.type == 'worker_died':
				del workers[e.worker.id]
				if e.worker.fly_machine:
					e.worker.fly_machine.delete()


		workers_lock.release()




def sort_workers():
	global workers
	old = sorted(workers, key=lambda w: w.last_seen, reverse=True)
	workers = {}
	for w in old:
		workers[w.id] = w
	


def find_new_task_for_worker(worker):
	log.debug('find_new_task_for_worker: %s', worker)
	if not worker.alive():
		log.debug('find_new_task_for_worker: worker not alive')
		return
	log.debug('find_new_task_for_worker: leng(pending_tasks)=%s', len(pending_tasks))
	for task in pending_tasks:
		if try_assign_worker_to_task(worker, task):
			return True
			
def match_worker_to_task(worker, task):
	return task.org == worker.org and task.size in worker.sizes

def try_assign_any_worker_to_task(task):
	log.debug('try_assign_any_worker_to_task: len(workers)=%s', len(workers))
	for _,worker in workers.items():
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
	








import threading
from datetime import time

from app.machine import list_machines
from untrusted_task import *


class Worker:
	def __init__(self, id):
		self.id = id
		self.sizes = [None]
		self.last_seen = last_seen
		self.task = None
		self.last_reported_task_ts = None
		self.last_reported_task = None
		self.fly_machine = None
	def alive(self):
		return self.last_seen > time.now() - 120		
		

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
	worker.last_seen = time.now()
	workers_lock.release()



def sort_workers():
	workers.sort(key=lambda w: w.last_seen, reverse=True)


def worker_janitor():
	while True:
		workers_lock.acquire()
		for worker in reversed(workers):
			if not worker.alive():
				if worker.task:
					events.push(dict(type='task_result', worker=worker, result=dict(
						result=dict(error='worker died'),
						task_id=worker.task.task_id
					)))
				workers.remove(worker)
				if worker.fly_machine:
					worker.fly_machine.delete()
				
		workers_lock.release()
		time.sleep(10)

threading.Thread(target=worker_janitor, daemon=True).start()



def fly_machine_janitor():
	if fly:
		while True:
	
			for machine in list_machines():
				for worker in workers:
					if worker.fly_machine.id == machine.id:
						break
				else:
					machine.delete()

	
			time.sleep(60)
			
threading.Thread(target=fly_machine_janitor, daemon=True).start()
		

def synchronization_thread():
	while True:
		e = events.pop()
		workers_lock.acquire()

		if e['type'] == 'add_task':
			sort_workers()
			task = e['task']
			try_assign_any_worker_to_task(task)	
	
		if e['type'] == 'task_result':
			if e['worker'].task:
				if e['result']['task_id'] == e['worker'].task.task_id:
					e['worker'].task.results.push(dict(result=e['result']['result']))
				e['worker'].task = None
				find_new_task_for_worker(e['worker'])

		workers_lock.release()


def find_new_task_for_worker(worker):
	if not worker.alive():
		return
	for task in pending_tasks:
		if try_assign_worker_to_task(worker, task):
			break
			
def match_worker_to_task(worker, task):
	return task.org == worker.org and task.size in worker.sizes

def try_assign_any_worker_to_task(task):
	for worker in workers:
		if try_assign_worker_to_task(worker, task):
			return

def try_assign_worker_to_task(worker, task):
	if match_worker_to_task(worker, task):
		assign_worker_to_task(worker, task)
		return True

def assign_worker_to_task(worker, task):
	worker.task = task
	pending_tasks.remove(task)
	








# a thread-safe counter to ensure unique tmp dir name. But it turns out that threads are not our only problem, another is celery spawning multiple processess(workers). That is disabled by "-c 1".

import threading

class AtomicInteger():
	""" https://stackoverflow.com/questions/23547604/python-counter-atomic-increment """
	def __init__(self, value=0):
		self._value = value
		self._lock = threading.Lock()

	def inc(self):
		with self._lock:
			self._value += 1
			return self._value

	def dec(self):
		with self._lock:
			self._value -= 1
			return self._value

	@property
	def value(self):
		with self._lock:
			return self._value

	@value.setter
	def value(self, v):
		with self._lock:
			self._value = v
			return self._value

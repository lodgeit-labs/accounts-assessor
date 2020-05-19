#!/usr/bin/env python3.8

from celery import Celery
app = Celery('tasks_test', broker='pyamqp://guest@localhost//')
import celeryconfig
#app.config_from_object(celeryconfig)
app.conf.task_default_queue = "tasks_test"


@app.task
def send_newsletter(email):
	import time
	time.sleep(2)
	print('sent newsletter:{0}'.format(email))
	if email == 3:
		raise 123

@app.task
def newsletter():
	users = range(4)
	for u in users:
		print('rpc-invoking with email:{0}'.format(u))
		send_newsletter.delay(u)

@app.task
def po(x):
	for i in range(x):
		if i**i == 67:
			break
	import sys
	return sys.flags

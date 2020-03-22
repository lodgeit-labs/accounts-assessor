#!/usr/bin/env python3.8

import os
import json
from celery import Celery

app = Celery(include=['internal_workers', 'call_prolog'])
	
import celeryconfig
app.config_from_object(celeryconfig)

# under mod_wsgi, this is set in wsgi.py
app.conf.task_default_queue = os.environ['CELERY_QUEUE_NAME']

with open(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../secrets2.json')), 'r') as s2:
	secrets = json.load(s2)
	app.conf.AGRAPH_SECRET_USER = secrets['AGRAPH_SECRET_USER']
	app.conf.AGRAPH_SECRET_PASSWORD = secrets['AGRAPH_SECRET_PASSWORD']
	del secrets

if __name__ == '__main__':
    app.start()
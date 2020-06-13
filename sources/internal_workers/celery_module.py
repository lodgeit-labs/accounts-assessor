#!/usr/bin/env python3.8

import os
import json
from celery import Celery

app = Celery(include=['internal_workers', 'invoke_rpc'])

import celeryconfig
app.config_from_object(celeryconfig)

# under mod_wsgi, this is set in wsgi.py
if 'CELERY_QUEUE_NAME' in os.environ:
	app.conf.task_default_queue = os.environ['CELERY_QUEUE_NAME']

with open(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../secrets2.json')), 'r') as s2:
	secrets = json.load(s2)
	app.conf.AGRAPH_SECRET_HOST = secrets.get('AGRAPH_SECRET_HOST')
	app.conf.AGRAPH_SECRET_PORT = secrets.get('AGRAPH_SECRET_PORT')
	app.conf.AGRAPH_SECRET_USER = secrets.get('AGRAPH_SECRET_USER')
	app.conf.AGRAPH_SECRET_PASSWORD = secrets.get('AGRAPH_SECRET_PASSWORD')
	del secrets


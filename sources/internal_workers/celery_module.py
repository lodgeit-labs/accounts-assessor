import os, sys
from celery import Celery
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
import celeryconfig


app = Celery(
	include=['internal_workers', 'invoke_rpc'],
	config_source = celeryconfig,
)
# under mod_wsgi, this is set in wsgi.py
if 'CELERY_QUEUE_NAME' in os.environ:
	app.conf.task_default_queue = os.environ['CELERY_QUEUE_NAME']


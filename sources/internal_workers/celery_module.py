import os, sys


from tmp_dir_path import git
os.chdir(git("server_root"))


if os.environ.get('NODOCKER', False):
	os.environ['SECRETS_DIR'] = '../secrets/nodocker'
	os.environ['SECRET__CELERY_RESULT_BACKEND_URL']='redis://localhost'
	os.environ['PYTHONUNBUFFERED']='true'
	os.environ['CELERY_QUEUE_NAME']='q7788'
	os.environ['SECRET__INTERNAL_SERVICES_SERVER_URL']="http://localhost:17788"
	os.environ['MPROF_OUTPUT_PATH']="mem"



from celery import Celery
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
import celeryconfig





app = Celery(
	include=['internal_workers', 'invoke_rpc', 'selftest'],
	config_source = celeryconfig,
)
# under mod_wsgi, this is set in wsgi.py
if 'CELERY_QUEUE_NAME' in os.environ:
	app.conf.task_default_queue = os.environ['CELERY_QUEUE_NAME']


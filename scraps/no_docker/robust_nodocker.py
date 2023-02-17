import os, sys

if os.environ.get('NODOCKER', False):
	os.environ['SECRETS_DIR'] = os.path.normpath(os.path.join(os.path.dirname(__file__), '../../secrets/'))
	os.environ['CELERY_RESULT_BACKEND_URL']='redis://localhost'
	os.environ['PYTHONUNBUFFERED']='true'
	os.environ['CELERY_QUEUE_NAME']='q7788'
	os.environ['INTERNAL_SERVICES_SERVER_URL']="http://localhost:17788"
	os.environ['MPROF_OUTPUT_PATH']="mem"
	os.environ['REDIS_HOST']='redis://localhost'

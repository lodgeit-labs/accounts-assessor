import os

if os.environ.get('NODOCKER', False):
	os.environ['SECRETS_DIR'] = '../secrets/nodocker/'
	os.environ['SECRET__CELERY_RESULT_BACKEND_URL']='redis://localhost'
	os.environ['PYTHONUNBUFFERED']='true'
	os.environ['CELERY_QUEUE_NAME']='q7788'
	os.environ['SECRET__INTERNAL_SERVICES_SERVER_URL']="http://localhost:17788"
	os.environ['MPROF_OUTPUT_PATH']="mem"


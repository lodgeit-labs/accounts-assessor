import os
broker_url = os.environ.get('SECRET__CELERY_BROKER_URL', 'pyamqp://')
#broker_url = os.environ['SECRET__CELERY_BROKER_URL']
result_backend = 'rpc://'
task_serializer = 'json'
result_serializer = 'json'
enable_utc = True

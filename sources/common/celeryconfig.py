import os
broker_url = os.environ.get('SECRET__CELERY_BROKER_URL', 'pyamqp://')
result_backend = 'rpc://'
task_serializer = 'json'
result_serializer = 'json'
enable_utc = True
task_default_queue = os.environ['CELERY_QUEUE_NAME']
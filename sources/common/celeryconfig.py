import os



broker_url = os.environ.get('SECRET__CELERY_BROKER_URL', 'pyamqp://')



#https://stackoverflow.com/questions/63860955/celery-async-result-get-hangs-waiting-for-result-even-after-celery-worker-has
result_backend=os.environ.get('SECRET__CELERY_RESULT_BACKEND_URL', 'redis://redis')
#result_backend = 'rpc://'



task_serializer = 'json'
result_serializer = 'json'
enable_utc = True
task_default_queue = os.environ['CELERY_QUEUE_NAME']
worker_cancel_long_running_tasks_on_connection_loss=True


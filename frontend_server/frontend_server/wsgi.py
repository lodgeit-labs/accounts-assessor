"""
WSGI config for frontend_server project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/3.0/howto/deployment/wsgi/
"""

import os

from django.core.wsgi import get_wsgi_application

# this is all wrong but there seems to be no sane way to pass configuration from mod_wsgi?
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'frontend_server.settings_prod')
os.environ['USE_CELERY'] = 'True'
os.environ['CELERY_QUEUE_NAME'] = 'q7768'


application = get_wsgi_application()

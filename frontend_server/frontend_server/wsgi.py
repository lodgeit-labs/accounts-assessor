"""
WSGI config for frontend_server project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/3.0/howto/deployment/wsgi/
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'frontend_server.settings')
os.environ['USE_CELERY'] = 'True'

application = get_wsgi_application()

"""
WSGI config for frontend_server project.
It exposes the WSGI callable as a module-level variable named ``application``.
For more information on this file, see
https://docs.djangoproject.com/en/3.0/howto/deployment/wsgi/
"""

# this is all wrong but there seems to be no sane way to pass configuration from mod_wsgi? It will be saner with gunicorn or somesuch. Or possibly, we'll just have multiple versions of this file. But assuming there is only one apache, there can only be one python version.
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'frontend_server.settings_prod')
os.environ['CELERY_QUEUE_NAME'] = 'q7768'
#fixme
os.environ['SECRET__INTERNAL_SERVICES_SERVER_URL'] ="http://localhost:17768"

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()

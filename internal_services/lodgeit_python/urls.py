from django.contrib import admin
from django.urls import path, include
from django.conf.urls import url

from modernrpc.views import RPCEntryPoint

urlpatterns = [
    path('admin/', admin.site.urls),
    path('message/', include('message.urls')),
    path('xml_xsd_validator/', include('xml_xsd_validator.urls')),
    path('json_diff/', include('json_diff.urls')),
    path('shell/', include('shell.urls')),
	url(r'^rpc/', RPCEntryPoint.as_view(enable_doc = True)),
]

from django.contrib import admin
from django.urls import path, include
from django.conf.urls import url

from modernrpc.views import RPCEntryPoint

urlpatterns = [
    path('admin/', admin.site.urls),
    path('message/', include('message.urls')),
   	url(r'^rpc/', RPCEntryPoint.as_view(enable_doc = True)),
    path('shell/', include('shell.urls')),
]

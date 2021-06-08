from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, re_path
from . import views
from django.views.generic.base import RedirectView

urlpatterns = ([
    re_path(r'^favicon\.ico$', RedirectView.as_view(url='/static/favicon.ico', permanent=True)),

    #this has to be a POST because we use an ancient .NET
    path('rdf_templates', views.rdf_templates, name='rdf_templates'),

    path('upload', views.upload, name='upload'),
    # path('', views.upload, name='upload'),

    # can be removed yet?
    #path('residency', views.residency, name='residency'),
    #path('sbe', views.sbe, name='sbe'),
    path('chat', views.chat, name='chat'),
    path('chat_v2', views.chat, name='chat_v2'),

    # path('sparql_proxy', views.sparql_proxy, name='sparql_proxy'),
    path('day', views.day)

    ] +
    # this is now fully replaced by apache
    []
    #static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT, show_indexes=True) +
    #static(settings.STATIC_URL, document_root=settings.STATIC_ROOT, show_indexes=True)
)


from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, re_path
from . import views
from django.views.generic.base import RedirectView

urlpatterns = ([
    re_path(r'^favicon\.ico$', RedirectView.as_view(url='/static/favicon.ico', permanent=True)),

    #this has to be a POST because we use an ancient .NET
    # ^ actually not, so, this route can be removed in favor of GETing /static/RdfTemplates.n3 directly
    path('rdf_templates', views.rdf_templates, name='rdf_templates'),

    path('upload', views.upload, name='upload'),
    # path('', views.upload, name='upload'),

    path('chat', views.chat, name='chat'),

    # path('sparql_proxy', views.sparql_proxy, name='sparql_proxy'),

    path('day', views.day),
    path('rpc', views.rpc)

    ] +
    # this is now fully replaced by apache
    []
    #static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT, show_indexes=True) +
    #static(settings.STATIC_URL, document_root=settings.STATIC_ROOT, show_indexes=True)
)


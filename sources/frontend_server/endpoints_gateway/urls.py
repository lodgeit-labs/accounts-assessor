from django.conf import settings
from django.conf.urls.static import static
from django.urls import path
from . import views

urlpatterns = ([
    path('', views.upload, name='upload'),
    path('upload', views.upload, name='upload'),
    path('sbe', views.sbe, name='sbe'),
    #path('test', views.test, name='test'),
    path('residency', views.residency, name='residency')] +
    static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT, show_indexes=True) +
    static(settings.STATIC_URL, document_root=settings.STATIC_ROOT, show_indexes=True)
)


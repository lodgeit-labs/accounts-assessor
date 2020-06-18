from django.urls import path

from . import views

urlpatterns = [
	path('', views.MessageList.as_view(), name='message_list'),
	path('view/<int:pk>', views.MessageView.as_view(), name='message_view'),
	path('new', views.MessageCreate.as_view(), name='message_new'),
	path('view/<int:pk>', views.MessageView.as_view(), name='message_view'),
	path('edit/<int:pk>', views.MessageUpdate.as_view(), name='message_edit'),
	path('delete/<int:pk>', views.MessageDelete.as_view(), name='message_delete'),
]

from django.http import JsonResponse
from django.http import HttpResponse
from django.views.generic import ListView, DetailView
from django.views.generic.edit import CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from message.models import Message


class MessageList(ListView):
	model = Message

class MessageView(DetailView):
	model = Message

fields = ['status','contents']

class MessageCreate(CreateView):
	model = Message
	fields = fields
	success_url = reverse_lazy('message_list')

class MessageUpdate(UpdateView):
	model = Message
	fields = fields
	success_url = reverse_lazy('message_list')

class MessageDelete(DeleteView):
	model = Message
	success_url = reverse_lazy('message_list')

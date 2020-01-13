from django.db import models

class Message(models.Model):
	status = models.TextField()
	contents = models.TextField()
	created = models.DateTimeField(auto_now_add=True)

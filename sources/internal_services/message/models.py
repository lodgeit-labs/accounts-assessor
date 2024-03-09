import json

from django.db import models

class Message(models.Model):
	status = models.TextField()
	contents = models.TextField()
	created = models.DateTimeField(auto_now_add=True)

	
	def contents_pretty(self):
		return json.dumps(json.loads(self.contents), indent=4)
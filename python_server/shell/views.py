import subprocess, shlex, json
#from django.http import HttpResponseRedirect
from django.shortcuts import redirect
from message.models import Message
from django.http.request import QueryDict

def index(request):
	""" fixme: limit these to some directories / hosts """
	params = QueryDict(mutable=True)
	params.update(request.POST)
	params.update(request.GET)
	cmd = params['cmd']
	p=subprocess.Popen(shlex.split(cmd),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,universal_newlines=True)#text=True)
	#output = '\n'.join(p.communicate())
	output = str(p.communicate())
	if p.returncode == 0:
		status = 'ok'
	else:
		status = 'error'
	m = Message(
		status=status,
		contents=json.dumps({
			'cmd':cmd,
			'output':output,
			'returncode':p.returncode}))
	m.save()
	return redirect('/message/view/%s'%m.id)
	#json_dumps_params={'default':str,'indent':4})

import subprocess, shlex, json
from django.http import HttpResponseRedirect, JsonResponse
from django.shortcuts import redirect
from message.models import Message
from django.http.request import QueryDict

def index(request):
	""" fixme: limit these to some directories / hosts """
	params = QueryDict(mutable=True)
	params.update(request.POST)
	params.update(request.GET)
	cmd = params['cmd']
	cmd = shlex.split(cmd)
	p=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,universal_newlines=True)#text=True)
	#output = '\n'.join(p.communicate())
	output = str(p.communicate())
	if p.returncode == 0:
		status = 'ok'
	else:
		status = 'error'
	if params.get('quiet_success') == True and status == 'ok':
		return JsonResponse({'status':'ok'})
	m = Message(
		status=status,
		contents=json.dumps({
			'cmd':cmd,
			'output':output,
			'returncode':p.returncode}))
	m.save()
	return redirect('/message/view/%s'%m.id)
	#json_dumps_params={'default':str,'indent':4})


def rpc(request):
	cmd = [shlex.quote(x) for x in json.loads(request.body)['cmd']]
	print(cmd)
	p = subprocess.Popen(cmd, universal_newlines=True)  # text=True)
	#p=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True)#text=True)
	(stdout,stderr) = p.communicate()
	if p.returncode == 0:
		status = 'ok'
	else:
		status = 'error'
	return JsonResponse({'status':status,'stdout':stdout,'stderr':stderr})

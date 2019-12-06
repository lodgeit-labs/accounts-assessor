from django.http import JsonResponse
import subprocess, shlex

def index(request):
	""" fixme: limit these to some directories / hosts """
	params = request.GET
	cmd = params['cmd']
	output=subprocess.check_output(shlex.split(cmd))
	return JsonResponse({'output':output, 'cmd':cmd}, json_dumps_params={'default':str,'indent':4})

from django.http import JsonResponse
import os

def index(request):
	""" fixme: limit these to some directories / hosts """
	params = request.GET
	cmd = params['cmd']
	return_code=os.system(cmd)
	return JsonResponse({'return_code':return_code, 'cmd':cmd}, json_dumps_params={'default':str,'indent':4})











import json, ntpath, os

from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponseRedirect, JsonResponse, HttpResponse
from django.shortcuts import redirect
from django.http.request import QueryDict

from endpoints_gateway.forms import ClientRequestForm

from lib import invoke_rpc_cmdline
from os import listdir
from os.path import isfile, join
import urllib.parse

def directory_files(directory):
	return [f for f in listdir(directory) if isfile(join(directory, f))]


def handle_uploaded_file(tmp_directory_path, f):
	tmp_fn = os.path.abspath('/'.join([tmp_directory_path, ntpath.basename(f.name)]))
	with open(tmp_fn, 'wb+') as destination:
		for chunk in f.chunks():
			destination.write(chunk)
	return tmp_fn

#    path('/upload', views.upload, name='upload'),

@csrf_exempt
def upload(request):
	params = QueryDict(mutable=True)
	params.update(request.POST)
	params.update(request.GET)

	requested_output_format = params.get('requested_output_format', 'json_reports_list')
	server_url = request._current_scheme_host
	MY_SERVICES_SERVER_URL = settings.MY_SERVICES_SERVER_URL
	if MY_SERVICES_SERVER_URL == None:
		# fixme, idk how to pass settings or env vars from mod_wsgi
		MY_SERVICES_SERVER_URL ="http://localhost:17768"
	prolog_flags = """set_prolog_flag(services_server,'""" + MY_SERVICES_SERVER_URL + """')"""

	if request.method == 'POST':
		#print(request.FILES)
		form = ClientRequestForm(request.POST, request.FILES)
		if form.is_valid():
			tmp_directory_name, tmp_directory_path = invoke_rpc_cmdline.create_tmp()
			request_files_in_tmp = []
			for field in request.FILES.keys():
				for f in request.FILES.getlist(field):
					print (f)
					request_files_in_tmp.append(handle_uploaded_file(tmp_directory_path, f))

			if 'only_store' in request.POST:
				return render(request, 'uploaded_files.html', {
					'files': [server_url + '/tmp/' + tmp_directory_name + '/' + urllib.parse.quote(f) for f in directory_files(tmp_directory_path)]})

			msg = {	"method": "calculator",
					"params": {
						"server_url": server_url,
						"tmp_directory_name": tmp_directory_name,
						"request_files": request_files_in_tmp}
			}
			try:
				invoke_rpc_cmdline.call_rpc(msg, prolog_flags=prolog_flags)
			except json.decoder.JSONDecodeError as e:
				return HttpResponse(status=500)
			if requested_output_format == 'xml':
				return HttpResponseRedirect('/tmp/' + tmp_directory_name + '/response.xml')
			else:
				return HttpResponseRedirect('/tmp/'+tmp_directory_name+'/response.json')
	else:
		form = ClientRequestForm()
	return render(request, 'upload.html', {'form': form})

def test(request):
	return {"a":AAA}

#    the chat endpoints

def sbe(request):
	return json_call({
		"method": "sbe",
		"params": json.loads(request.body)
	})

def residency(request):
	return json_call({
		"method": "residency",
		"params": json.loads(request.body)
	})

def json_call(msg):
	try:
		return JsonResponse(invoke_rpc_cmdline.call_rpc(msg))
	except json.decoder.JSONDecodeError as e:
		return HttpResponse(status=500)


#import IPython; IPython.embed()

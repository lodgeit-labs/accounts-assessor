import json, ntpath, os

from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponseRedirect, JsonResponse
from django.shortcuts import redirect
from django.http.request import QueryDict

from endpoints_gateway.forms import ClientRequestForm

from lib import invoke_rpc_cmdline



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
	server_url = request._current_scheme_host

	if request.method == 'POST':
		form = ClientRequestForm(request.POST, request.FILES)
		if form.is_valid():
			tmp_directory_name, tmp_directory_path = invoke_rpc_cmdline.create_tmp()
			request_files_in_tmp = []
			if 'file1' in form.files:
				request_files_in_tmp.append(handle_uploaded_file(tmp_directory_path, form.files['file1']))
			if 'file2' in form.files:
				request_files_in_tmp.append(handle_uploaded_file(tmp_directory_path, form.files['file2']))
			invoke_rpc_cmdline.call_rpc(server_url, tmp_directory_name, request_files_in_tmp)
			return HttpResponseRedirect('/tmp/'+tmp_directory_name+'/response.json')
	else:
		form = ClientRequestForm()
	return render(request, 'upload.html', {'form': form})


#    path('/sbe', views.sbe, name='sbe'),

def sbe(request):
	raise NotImplementedError()

#    path('/residency', views.residency, name='residency'),

def residency(request):
	raise NotImplementedError()


import sys, os
# for the case when running standalone
# is this needed?
#sys.path.append('../internal_workers')
# for running under mod_wsgi
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../internal_workers')))


import urllib.parse
import json
import celery
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponseRedirect, JsonResponse, HttpResponse
from django.shortcuts import redirect
from django.http.request import QueryDict
from endpoints_gateway.forms import ClientRequestForm
from fs_utils import directory_files, save_django_uploaded_file, save_django_form_uploaded_file
import invoke_rpc
from invoke_rpc import call_prolog_calculator
from tmp_dir_path import create_tmp


def tmp_file_url(server_url, tmp_dir_name, fn):
	return server_url + '/tmp/' + tmp_dir_name + '/' + urllib.parse.quote(fn)


@csrf_exempt
def upload(request):
	server_url = request._current_scheme_host
	params = QueryDict(mutable=True)
	params.update(request.POST)
	params.update(request.GET)
	requested_output_format = params.get('requested_output_format', 'json_reports_list')
	prolog_flags = """set_prolog_flag(services_server,'""" + settings.SECRET__INTERNAL_SERVICES_SERVER_URL + """')"""

	if request.method == 'POST':
		#print(request.FILES)
		form = ClientRequestForm(request.POST, request.FILES)
		if form.is_valid():

			request_tmp_directory_name, request_tmp_directory_path = invoke_rpc.create_tmp()

			request_files_in_tmp = []
			for field in request.FILES.keys():
				for f in request.FILES.getlist(field):
					#print (f)
					request_files_in_tmp.append(save_django_uploaded_file(request_tmp_directory_path, f))

			#for idx, f in enumerate(form.data.getlist('file1')):
			#	request_files_in_tmp.append(save_django_form_uploaded_file(request_tmp_directory_path, idx, f))
			#import IPython; IPython.embed()

			if 'only_store' in request.POST:
				return render(request, 'uploaded_files.html', {
					'files': [tmp_file_url(server_url, request_tmp_directory_name, f) for f in directory_files(request_tmp_directory_path)]})

			final_result_tmp_directory_name, final_result_tmp_directory_path = create_tmp()
			try:
				response_tmp_directory_name = call_prolog_calculator(
					prolog_flags=prolog_flags,
					request_tmp_directory_name=request_tmp_directory_name,
					server_url=server_url,
					request_files=request_files_in_tmp,
					use_celery=True,
					timeout_seconds=20,
					final_result_tmp_directory_name=final_result_tmp_directory_path
				)
			except celery.exceptions.TimeoutError:
				if requested_output_format == 'json_reports_list':
					return JsonResponse(
					{
						'alerts': ['task is still processing..'],
						"reports":
						[{
							"title": "frontend_server_timeout",
							"key": "please refresh",
							"val":{"url": tmp_file_url(server_url, final_result_tmp_directory_name, '')}}
						]
					})
				else:
					raise
			if requested_output_format == 'xml':
				return HttpResponseRedirect('/tmp/' + response_tmp_directory_name + '/response.xml')
			else:
				return HttpResponseRedirect('/tmp/'+ response_tmp_directory_name + '/response.json')


	else:
		form = ClientRequestForm()
	return render(request, 'upload.html', {'form': form})



#  ┏━╸╻ ╻┏━┓╺┳╸
#  ┃  ┣━┫┣━┫ ┃
#  ┗━╸╹ ╹╹ ╹ ╹

def sbe(request):
	return json_prolog_rpc_call({
		"method": "sbe",
		"params": json.loads(request.body)
	})

def residency(request):
	return json_prolog_rpc_call({
		"method": "residency",
		"params": json.loads(request.body)
	})

def json_prolog_rpc_call(msg):
	#try:
	return JsonResponse(invoke_rpc.call_prolog.apply_async(msg).get()[1])
	#except json.decoder.JSONDecodeError as e:
	#	return HttpResponse(status=500)


#import IPython; IPython.embed()

# todo https://www.honeycomb.io/microservices/

#todo:
#@sensitive_variables('user', 'pw', 'cc') # https://simpleisbetterthancomplex.com/tips/2016/11/01/django-tip-19-protecting-sensitive-information.html
# @sensitive_post_parameters('pass_word', 'credit_card_number')



"""
todo: eventually i'd like to switch to a tasks manager based on the triplestore

@csrf_exempt
def results(request):
	...

SELECT ?rep WHERE {
	?req rdf:type l:Request.
  	?req l:client_code "xx".
  	?req l:has_result ?res.
  	?res l:has_report ?rep.
  	?rep l:key "reports_json".  
}

"""

			#except json.decoder.JSONDecodeError as e:
				# call _ prolog lets this exception propagate. The assumption is that if prolog finished successfully, it returned a json, but if it failed in some horrible way (syntax errors), the output won't parse as json.
				#return HttpResponse(status=500)



# /*
# note on request processing:
# (for future)
# (in addition to handling and presenting the facts of existence of a request, the status of processing, retries after worker failures)
# with pyco, we would optimize clause order to arrive at a complete solution / result in the shortes time in usual cases, but we should be able to present alternative solutions, and also present the situation that some solutions have been found but the search is still in progress.
# */
#


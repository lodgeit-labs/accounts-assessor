import sys, os


# if running standalone:
#sys.path.append('../internal_workers')

# if running under mod_wsgi
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../internal_workers')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common')))

from agraph import agc

import urllib.parse
import json
import datetime


import celery
import celeryconfig
celery_app = celery.Celery(config_source = celeryconfig)

from ipware import get_client_ip
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponseRedirect, JsonResponse, HttpResponse
from django.http.request import QueryDict
from endpoints_gateway.forms import ClientRequestForm
from fs_utils import directory_files, save_django_uploaded_file, save_django_form_uploaded_file
from tmp_dir_path import create_tmp
import call_prolog_calculator
import logging


def tmp_file_url(server_url, tmp_dir_name, fn):
	return server_url + '/tmp/' + tmp_dir_name + '/' + urllib.parse.quote(fn)


@csrf_exempt
def sparql_proxy(request):
	if request.method == 'POST':
		return JsonResponse({"x":agc().executeGraphQuery(request.body)})

@csrf_exempt
def rdf_templates(request):
	import time
	time.sleep(2)
	return HttpResponse(open(os.path.abspath('../static/RdfTemplates.n3'), 'r').read(), content_type="text/rdf+n3")

@csrf_exempt
def upload(request):
	server_url = os.getenv('PUBLIC_URL', request._current_scheme_host)
	params = QueryDict(mutable=True)
	params.update(request.POST)
	params.update(request.GET)
	requested_output_format = params.get('requested_output_format', 'json_reports_list')
	request_format = params.get('request_format')
	if not request_format:
		raise Exception('missing request_format')

	prolog_flags = """set_prolog_flag(services_server,'""" + settings.SECRET__INTERNAL_SERVICES_SERVER_URL + """')"""

	if request.method == 'POST':
		#print(request.FILES)
		form = ClientRequestForm(request.POST, request.FILES)
		if form.is_valid():

			request_tmp_directory_name, request_tmp_directory_path = create_tmp()

			request_files_in_tmp = []
			for field in request.FILES.keys():
				for f in request.FILES.getlist(field):
					request_files_in_tmp.append(save_django_uploaded_file(request_tmp_directory_path, f))

			#for idx, f in enumerate(form.data.getlist('file1')):
			#	request_files_in_tmp.append(save_django_form_uploaded_file(request_tmp_directory_path, idx, f))
			#import IPython; IPython.embed()

			if 'only_store' in request.POST:
				return render(request, 'uploaded_files.html', {
					'files': [tmp_file_url(server_url, request_tmp_directory_name, f) for f in
							  directory_files(request_tmp_directory_path)]})


			final_result_tmp_directory_name, final_result_tmp_directory_path = create_tmp()
			response_tmp_directory_name = None
			try:
				response_tmp_directory_name = call_prolog_calculator.call_prolog_calculator(
					celery_app = celery_app,
					prolog_flags=prolog_flags,
					request_tmp_directory_name=request_tmp_directory_name,
					server_url=server_url,
					request_files=request_files_in_tmp,
					# the limit here is that the excel plugin doesn't do any async or such. It will block until either response is received or it timeouts.
					# for json_reports_list, we must choose a timeout that happens faster than client's timeout. If client timeouts, it will have received nothing and can't even open browser or let user load result sheets manually
					# but if we timeout too soon, we will have no chance to send a full reports list with result sheets, and users will get an unnecessary browser window + will have to load sheets manually.
					# for xml there is no way to indicate any errors, so just let client do the timeouting.
					timeout_seconds = 30 if requested_output_format == 'json_reports_list' else 0,
					request_format = request_format,
					final_result_tmp_directory_name = final_result_tmp_directory_name,
					final_result_tmp_directory_path = final_result_tmp_directory_path
				)
			except celery.exceptions.TimeoutError:
				if requested_output_format == 'xml':
					raise

			logging.getLogger().warn('requested_output_format: %s' % requested_output_format)
			if requested_output_format == 'xml':
				reports = json.load(open('/app/server_root/tmp/' + response_tmp_directory_name + '/000000_response.json.json'))
				redirect_url = find_report_by_key(reports['reports'], 'response')
			else:
				if response_tmp_directory_name == None: # timeout happened
					return JsonResponse(
					{
						"alerts": ["timeout."],
						"reports":
						[{
							"title": "task_handle",
							"key": "task_handle",
							"val":{"url": tmp_file_url(server_url, final_result_tmp_directory_name, '')}}
						]
					})
				else:
					if requested_output_format == 'json_reports_list':
						redirect_url = '/tmp/'+ response_tmp_directory_name + '/000000_response.json.json'
					else:
						raise Exception('unexpected requested_output_format')
			logging.getLogger().warn('redirect url: %s' % redirect_url)
			return HttpResponseRedirect(redirect_url)


	else:
		form = ClientRequestForm()
	return render(request, 'upload.html', {'form': form})



def find_report_by_key(reports, name):
	for i in reports:
		if i['key'] == name:
			return i['val']['url']


def day(request):
	"""this is just for testing of monitoring apps"""
	return render(request, 'day.html', {'day': datetime.date.today().day})


def chat(request):
	return json_prolog_rpc_call(request, {
		"method": "chat",
		"params": json.loads(request.body),
	})


def json_prolog_rpc_call(request, msg):
	msg["client"] = get_client_ip(request)
	logging.getLogger().info(msg)
	return JsonResponse(celery_app.signature('invoke_rpc.call_prolog').apply_async([msg]).get()[1])


def rpc(request):
	if request.method != 'POST':
		return
	logging.getLogger().warn(('rpc', request,))
	sys.stderr.flush()

	task = agc().createBNode()

	target_server_url = 'http://localhost:88'
	logging.getLogger().info(f'start_selftest_session {target_server_url=}')

	chain = celery_app.signature('selftest.assert_selftest_session', (str(task), target_server_url))	| celery_app.signature('selftest.continue_selftest_session2')
	chain()




	return JsonResponse({'@id':str(task)})




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
...
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


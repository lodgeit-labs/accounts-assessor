WIP


def self_test(request):
	"""we could also have a standalone/commandline test runner, but this is a good start"""

	if request.method != 'POST':
		return

	final_result_tmp_directory_name, final_result_tmp_directory_path = create_tmp()

	# response_tmp_directory_name = call_prolog_calculator.call_prolog_calculator(
	# 	celery_app=celery_app,
	# 	prolog_flags=prolog_flags,
	# 	request_tmp_directory_name="dummy",
	# 	server_url=server_url,
	# 	request_files=[],
	# 	timeout_seconds=0,
	# 	request_format='dummy',
	# 	final_result_tmp_directory_name=final_result_tmp_directory_name,
	# 	final_result_tmp_directory_path=final_result_tmp_directory_path
	# )

	msg = {"method": "self_test",
		   "params": {
			   "server_url": server_url,
			   "final_result_tmp_directory_name": final_result_tmp_directory_name,
			   "final_result_tmp_directory_path": final_result_tmp_directory_path,
		   }
	}

	payload = {'msg': msg}
	if celery_app:
		task = celery_app.signature('invoke_rpc.call_prolog').apply_async(payload)
		response_tmp_directory_name, _result_json = task.get(timeout=0)
	else:
		from invoke_rpc import call_prolog
		response_tmp_directory_name, _result_json = call_prolog(payload)
	return response_tmp_directory_name


return json_prolog_rpc_call(request, {
		"method": "self_test",
	})

"""we could also have a standalone/commandline test runner, but this is a good start"""
return json_prolog_rpc_call(request, {
	"method": "self_test",
})

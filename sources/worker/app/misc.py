import shlex, os



def uri_params(params):

	# comment(RDF_EXPLORER_1_BASE, comment, 'base of uris to show to user in generated html')
	rdf_namespace_base = params['public_url'] + '/rdf/'
	tmp_directory_name = params['result_tmp_directory_name']
	request_uri = rdf_namespace_base + 'requests/' + tmp_directory_name

	return {
		'result_data_uri_base': rdf_namespace_base + 'results/' + tmp_directory_name + '/',
		"request_uri": request_uri,
		"rdf_namespace_base": rdf_namespace_base
	}



def env_string(dict):
	r = ""
	for k,v in dict.items():
		r += f"""{k}={shlex.quote(v)} \\\n"""
	return r




import shlex


def uri_params(tmp_directory_name):
	# comment(RDF_EXPLORER_1_BASE, comment, 'base of uris to show to user in generated html')
	rdf_explorer_base = 'http://dev-node.uksouth.cloudapp.azure.com:10036/#/repositories/a/node/'
	rdf_explorer_base = 'http://localhost:10055/#/repositories/a/node/'
	#rdf_namespace_base = 'http://dev-node.uksouth.cloudapp.azure.com/rdf/'
	rdf_namespace_base = 'https://rdf.tmp/'
	request_uri = rdf_namespace_base + 'requests/' + tmp_directory_name
	return {
		"request_uri": request_uri,
		"rdf_namespace_base": rdf_namespace_base,
		"rdf_explorer_bases": [rdf_explorer_base]
	}


def env_string(dict):
	r = ""
	for k,v in dict.items():
		r += f"""{k}={shlex.quote(v)} \\\n"""
	return r


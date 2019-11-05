:- module(xml, [
	validate_xml/3
]).

:- use_module(library(xsd/flatten)).
:- use_module(library(http/json)).
:- use_module(library(http/http_open)).


/*
Like `xml_flatten/2` from library(xsd/flatten) but works on already loaded XML objects instead of filepaths.
*/
flatten_xml(XML, ID) :-
	flatten:root_id(Root_ID),
	flatten:register_file_id(ID),
	flatten:xml_flatten_nodes(ID,Root_ID,0,XML),
	!.

xsd_validator_url('http://localhost:8000/xml_xsd_validator').

/*
Validates an XML instance against an XSD schema by calling an external Python script
*/
validate_xml(Instance_File, Schema_File, Schema_Errors) :-
	uri_encoded(query_value,Instance_File,Instance_File_Encoded),
	uri_encoded(query_value,Schema_File,Schema_File_Encoded),
	xsd_validator_url(XSD_Validator_URL),
	atomic_list_concat(['xml',Instance_File_Encoded], "=", Instance_File_Query_Component),
	atomic_list_concat(['xsd',Schema_File_Encoded], "=", Schema_File_Query_Component),
	atomic_list_concat([Instance_File_Query_Component, Schema_File_Query_Component], "&", Query),
	atomic_list_concat([XSD_Validator_URL,Query],"/?",Request_URI),
	%format("Request URI: ~w~n", [Request_URI]),
	setup_call_cleanup(
        http_open(Request_URI, In, [request_header('Accept'='application/json')]),
        json_read_dict(In, Response_JSON),
        close(In)
    ),
	%format("Result: ~w~n", [Response_JSON.result]),
	(
		Response_JSON.result = "ok"
	->
		Schema_Errors = []
	;
		atomic_list_concat([Response_JSON.error_type, Response_JSON.error_message], ": ", Schema_Error),
		Schema_Errors = [error:Schema_Error]
	).	
	/*
	Args = ['../python/src/xmlschema_runner.py',Instance_File,Schema_File],
	catch(
		setup_call_cleanup(
			process_create('../python/venv/bin/python3',Args,[]),
			true,
			true
		),
		_,
		throw('Input file failed XSD schema validation.')
	).
	*/

% ===================================================================
% Project:   LodgeiT
% Module:    Prolog Server
% Author:    Schwitter
% Date:      2019-06-08
% ===================================================================

:- module(prolog_server, [run_simple_server/0, run_daemon/0]).

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------
:- use_module(library(xpath)).
:- use_module(library(http/http_host)).
:- use_module(library(http/json)).
:- use_module(library(http/mimetype), []).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_header)).
:- use_module(library(http/http_multipart_plugin)).
:- use_module(library(http/http_client)).
:- use_module(library(http/html_write)).
:- use_module(library(option)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_error)). 

:- use_module('files', [bump_tmp_directory_id/0, absolute_tmp_path/2]).
:- use_module('residency').
:- use_module('sbe').
:- ensure_loaded('process_data').


mime:mime_extension('xsd', 'application/xml').

% -------------------------------------------------------------------
% Handler
% -------------------------------------------------------------------

:- http_handler(root(.),      upload_form, []).
:- http_handler(root(upload), upload,      []).
:- http_handler(root(upload_and_get_json_reports_list), upload_and_get_json_reports_list,      []).
:- http_handler(root(sbe), sbe_request, [methods([post])]).
:- http_handler(root(residency), residency_request, [methods([post])]).
:- http_handler('/favicon.ico', http_reply_file(my_static('favicon.ico'), []), []).
% TODO : - http_handler(root(tmp), http_reply_from_files('./tmp', []), [prefix]).
:- http_handler(root(.), http_reply_from_files('.', []), [prefix]).
/*fixme*/:- http_handler(root(run/Test), tests(Test), [methods([get])]).

% -------------------------------------------------------------------
% run_simple_server/0
% -------------------------------------------------------------------

run_simple_server :-
   Port_Number = 8080,
   %Python_Port_Number is Port_Number + 20,
   %utils:shell2(['cd ../python_server;./run.sh --noreload ', Python_Port_Number, ';&'],0),
   http_server(http_dispatch, [port(Port_Number)]).

% -------------------------------------------------------------------
% run_daemon/0
% -------------------------------------------------------------------

run_daemon :-
   use_module(library(http/http_unix_daemon)),
   http_daemon.
   
% -------------------------------------------------------------------
% upload_form/1
% -------------------------------------------------------------------

upload_form(_Request) :-
reply_html_page(
			title('LodgeiT Demo'),
		[ 
			h1('LodgeiT Demo'),
			form(
				[
					method('POST'),
					action(location_by_id(upload)),
					enctype('multipart/form-data')
				],
				table([],
				[
					tr([td(input([type(file), name(file)]))]),
					tr([td(['taxonomy URLs:']), td(
						select(name=relativeurls, [
							option([selected='true',value=0],[absolute]), 
							option([value=1],[relative])
					]))]),
					tr([td(['output format:']), td(
						select(name=requested_output_format, [
							option([selected='true',value=json_reports_list],[json_reports_list]), 
							option([value=xml],[xml])
					]))]),
					tr([td(align(left), input([type(submit), value('Upload XML file')]))])
				])
			),
			h2('instructions'),
			p(['Upload your request xml file here. You can also browse ', a([href="http://dev-node.uksouth.cloudapp.azure.com:7778/tests/endpoint_tests/"], 'available example request files'),' and ', a([href="http://dev-node.uksouth.cloudapp.azure.com:7778/run/endpoint_tests/depreciation/depreciation-request-depreciation-between-dates-all-years.xml"], 'run them directly like this')]),
			p(['a new directory is generated for each request: ', a([href="http://dev-node.uksouth.cloudapp.azure.com:7778/tmp/"], 'tmp/'), ', where you should be able to find the uploaded request file and generated report files.'])
		]).
		
upload(Request) :-
	multipart_post_request(Request), !,
	bump_tmp_directory_id, /*assert a unique thread-local my_tmp for each request*/
	http_read_data(Request, Parts, [ on_filename(files:save_file) ]),
	Options = Parts,
	catch(
		process_request(Request, Options, Parts),
		string(E),
		throw(http_reply(bad_request(string(E))))
		/* TODO (optionally only if the request content type is xml), return the errror as xml. the status code still should be bad request, but it's not required. 
		are we able to throw a bad_request and have the server produce a xml error page? if not, we'll need to 
		%writeln('<xml errror blablabla>'), but this means endpoints cannot write anything to the output stream until 
		everything's done. The option of generating the responses in a structured way has a lot of open questions (streaming..), so probably just redirecting endpoint's output to a file will be best choice now.
		*/
	).
/*
:- guitracer.		
:- tspy(upload/1).
*/

upload(_, _) :-
   throw(http_reply(bad_request(bad_file_upload))).

/*
 run a testcase directly, without uploading
*/
/*fixme
tests(Url, Request) :-
	bump_tmp_directory_id,
	absolute_file_name(my_tests(Url), Test_File_Path, [ access(read), file_errors(fail) ]),
	copy_test_file_into_tmp(Test_File_Path, Url),
	process_request(Url, Test_File_Path, Request, []).
*/
copy_test_file_into_tmp(/*+*/Path, /*+*/Url) :-
	tmp_file_path_from_url(Url, Tmp_Request_File_Path),
	copy_file(Path, Tmp_Request_File_Path).

% -------------------------------------------------------------------
% multipart_post_request/1
% -------------------------------------------------------------------

multipart_post_request(Request) :-
   memberchk(method(post), Request),
   memberchk(content_type(ContentType), Request),
   http_parse_header_value(content_type, ContentType, media(multipart/'form-data', _)).


% -------------------------------------------------------------------
% message/1
% -------------------------------------------------------------------

:- multifile prolog:message//1.

prolog:message(bad_file_upload) -->
   [ 'A file upload must be submitted as multipart/form-data POST request using', nl,
      'name=file and providing a file-name' ].

prolog:message(string(S)) --> [ S ].


process_request(Request, Options0, Parts) :-
	(
		member(search(GET_Options), Request)
	->
		append(Options0, GET_Options, Options2)
	;
		Options2 = Options0
	),
	
	http_public_host_url(Request, Server_Public_Url),
	set_server_public_url(Server_Public_Url),
	get_requested_output_type(Options2, Requested_Output_Type),

	(
		Requested_Output_Type = xml
	->
		format('Content-type: text/xml~n~n')
	;
		format('Content-type: application/json~n~n')
	),

	process_data(Options2, Parts).


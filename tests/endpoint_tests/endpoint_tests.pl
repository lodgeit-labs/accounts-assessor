% ===================================================================
% Project:   LodgeiT
% Date:      2019-07-09
% ===================================================================

:- module(endpoint_tests, []).

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- use_module(library(debug), [assertion/1]).
:- use_module(library(http/http_client)).
:- use_module(library(http/json)).
:- use_module(library(http/http_open)).
:- use_module(library(xpath)).
:- use_module(library(readutil)).
:- use_module('../../lib/files').
:- use_module('../../lib/prolog_server').
:- use_module('compare_xml').
:- use_module('../../lib/utils', [
		floats_close_enough/2]).
:- use_module('../../lib/xml').

/* we run all the tests against the http server that we start in this process. This makes things a bit confusing. But the plan is to move to a python (or aws) gateway */
:- begin_tests(xml_testcases, [setup((debug,run_simple_server))]).

test(start) :- nl.

/*
hardcoded plunit test rules, one for each endpoint, so we can use things like "throws"
*/

test(ledger, 
	[forall(testcases('endpoint_tests/ledger',Testcase))]) :-
	run_endpoint_test(ledger, Testcase).

test(loan, 
	[forall(testcases('endpoint_tests/loan',Testcase))]) :-
	run_endpoint_test(loan, Testcase).

test(depreciation, 
	[forall(testcases('endpoint_tests/depreciation',Testcase))]) :-
	run_endpoint_test(depreciation, Testcase).

test(livestock, 
	[forall(testcases('endpoint_tests/livestock',Testcase))]) :-
	run_endpoint_test(livestock, Testcase).

test(investment, 
	[forall(testcases('endpoint_tests/investment', Testcase))]) :-
	run_endpoint_test(investment, Testcase).

test(car, 
	[forall(testcases('endpoint_tests/car',Testcase)), fixme('NER API server is down.')]) :-
	run_endpoint_test(car, Testcase).

test(depreciation_invalid, 
	[forall(testcases('endpoint_tests/depreciation_invalid',Testcase)), throws(_)]) :-
	run_endpoint_test(depreciation_invalid, Testcase).

:- end_tests(xml_testcases).

/* mapping endpoints to response xsd files */
output_schema(loan,'responses/LoanResponse.xsd').
output_schema(depreciation,'responses/DepreciationResponse.xsd').
output_schema(livestock,'responses/LivestockResponse.xsd').
output_schema(investment,'responses/InvestmentResponse.xsd').
output_schema(car,'responses/CarAPIResponse.xsd').
output_taxonomy(ledger,'taxonomy/basic.xsd').


output_file(loan, 'response_xml', xml).
output_file(depreciation, 'response_xml', xml).
output_file(livestock, 'response_xml', xml).
output_file(investment, 'response_xml', xml).
output_file(car, 'response_xml', xml).
output_file(ledger, 'response_xml', xml).
output_file(ledger, 'general_ledger_json', json).
output_file(ledger, 'investment_report_json', json).
output_file(ledger, 'investment_report_since_beginning_json', json).


testcase_request_xml_file_path(Testcase, Request_XML_File_Path) :-
	atomic_list_concat([Testcase, "request.xml"], "/", Request_XML_File_Path).

/*
new design:


*/

run_endpoint_test(Type, Testcase) :-
	testcase_request_xml_file_path(Testcase, Request_XML_File_Path),
	query_endpoint(Request_XML_File_Path, Response_JSON),
	gtrace,




	tmp_uri_to_path(Response_JSON.reports.response_xml.url, Response_XML_Path),
	check_output_schema(Type, Response_XML_Path),
	% todo: xbrl validation on ledger response XBRL
	%check_output_taxonomy(Type, Response_XML_Path),

	tmp_uri_to_saved_response_path(Testcase, Response_JSON.reports.response_xml.url, Saved_Response_XML_Path),

	(
		\+exists_file(Saved_Response_XML_Path)
	->
		(
			print_alerts(Response_JSON, ['ERROR', 'WARNING', 'SYSTEM_WARNING']),
			/* if we have no saved xml response, and there are alerts in the json, fail the test */
			Response_JSON.alerts = []
		)
	;
		(
			print_alerts(Response_JSON, ['SYSTEM_WARNING']),
			findall(
				Errors,
				(
					output_file(Type, File_ID, File_Type),
					check_saved_response(Testcase, Response_JSON, File_ID, File_Type, Errors)
				),
				Error_List
			),
			flatten(Error_List, Error_List_Flat),
			(
				Error_List_Flat = []
			->
				true
			;
				(
					format("Errors: ~w~n", [Error_List_Flat]),
					fail
				)
			)
		)
	),
	!,
	% because we use gensym in investment reports and it will keep incrementing throughout the test-cases, causing fresh responses to not match saved responses.
	reset_gensym(iri).

check_reports(Response_JSON, Urls) :-
	dict_pairs(Response_JSON.reports, _, Pairs),
	maplist(check_report, Pairs, ).
	

check_report(Pair) :-
	Pair.url,
	Pair.
	

check_saved_response(Testcase, Response_JSON, File_ID, File_Type, Errors) :-
	(
		get_dict(File_ID, Response_JSON.reports, _)
	->
		(
			tmp_uri_to_saved_response_path(Testcase, Response_JSON.reports.File_ID.url, Saved_Response_Path),
			(
				exists_file(Saved_Response_Path)
			->
				(
					format("## Testing Response File: ~w~n", [Saved_Response_Path]),
					test_response(Response_JSON.reports.File_ID.url, Saved_Response_Path, File_Type, Errors0),
					findall(
						File_ID:Error,
						member(Error,Errors0),
						Errors
					)
				)
			;
				Errors = []
			)
		)
	;
		Errors = []
	).

test_response(Response_URL, Saved_Response_Path, xml, Errors) :-
	http_get(Response_URL, Response_XML, []),
	load_structure(string(Response_XML), Response_DOM,[dialect(xml),space(sgml)]),

	load_xml(Saved_Response_Path, Saved_Response_DOM, [space(sgml)]),
	compare_xml_dom(Response_DOM, Saved_Response_DOM, Error),
	(
		var(Error)
	->
		Errors = []
	;
		Errors = [Error], 
		(
			get_flag(overwrite_response_files, true)
		->
			(
				open(Saved_Response_Path, write, Stream),
				xml_write(Stream, Response_DOM, []),
				close(Stream)
			)
		)
	).


test_response(Response_URL, Saved_Response_Path, json, Error) :-
	setup_call_cleanup(
        http_open(Response_URL, In, [request_header('Accept'='application/json')]),
        json_read_dict(In, Response_JSON),
        close(In)
    ),
	setup_call_cleanup(
		open(Saved_Response_Path, read, Saved_Response_Stream, []),
		json_read_dict(Saved_Response_Stream, Saved_Response_JSON),
		close(Saved_Response_Stream)
	),	
	(
		Response_JSON = Saved_Response_JSON
	->
		Error = []
	;
		Error = ["JSON not equal"]
	).
		
	


print_alerts(Response_JSON, Alert_Types) :-
	findall(
		_,
		(
			member(_{type:Type,value:Alert}, Response_JSON.alerts),
			member(Type, Alert_Types),
			format("~w: ~w~n", [Type, Alert])
		),
		_
	).

check_value_difference(Value1, Value2) :-
	atom_number(Value1, NValue1),
	atom_number(Value2, NValue2),
	floats_close_enough(NValue1, NValue2).

query_endpoint(RequestFile0, Response_JSON) :-
	write('## Testing Request File: '), writeln(RequestFile0),
	absolute_file_name(my_tests(
		RequestFile0),
		RequestFile,
		[ access(read) ]
	),
	http_post('http://localhost:8080/upload?requested_output_format=json_reports_list', form_data([file=file(RequestFile)]), Response_String, [content_type('multipart/form-data')]),
	%http_post('http://localhost:8080/upload?requested_output_format=xml', form_data([file=file(RequestFile)]), ReplyXML, [content_type('multipart/form-data')]),
	/*todo: status_code(-Code)
If this option is present and Code unifies with the HTTP status code, do not translate errors (4xx, 5xx) into an exception. Instead, http_open/3 behaves as if 2xx (success) is returned, providing the application to read the error document from the returned stream.
*/

    atom_json_dict(Response_String, Response_JSON_Raw,[value_string_as(atom)]),
	findall(
		ID-_{title:Title,url:URL},
		member(_{id:ID,key:Title,val:_{url:URL}}, Response_JSON_Raw.reports),
		Reports
	),
	dict_pairs(Reports_Dict,_,Reports),
	Response_JSON = _{
		alerts:Response_JSON_Raw.alerts,
		reports:Reports_Dict
	}.


testcases(Top_Level, Testcase) :-
	format("testcases: ~w~n", [Top_Level]),
	find_test_cases_in(Top_Level, Testcase).

/*
if there's a "request.xml" file, it's a test-case directory, so yield it,
otherwise, recurse over subdirectories
*/

find_test_cases_in(Current_Directory, Test_Case) :-
	absolute_file_name(my_tests(Current_Directory), Current_Directory_Absolute, [file_type(directory)]),
	directory_files(Current_Directory_Absolute, Entries),
	(
		member('request.xml',Entries)
	->
		Test_Case = Current_Directory
	;
		(
			member(Subdirectory, Entries),
			\+member(Subdirectory, ['.','..']),
			atomic_list_concat([Current_Directory, Subdirectory], '/', Subdirectory_Relative_Path),	
			catch(
				(
					absolute_file_name(my_tests(Subdirectory_Relative_Path), Subdirectory_Absolute_Path, [file_type(directory)]),
					exists_directory(Subdirectory_Absolute_Path),
					find_test_cases_in(Subdirectory_Relative_Path, Test_Case)
				),
				_,
				fail
			)	
		) 
	).


tmp_uri_to_path(URI, Path) :-
	uri_components(URI, uri_components(_,_,Path0,_,_)),
	atom_string(Path0, Path0_String),
	split_string(Path0_String,"/","",[_|[_|Path_Components]]),
	atomic_list_concat(Path_Components,"/",Relative_Path),
	absolute_file_name(my_tmp(Relative_Path), Path, []).

tmp_uri_to_saved_response_path(Testcase, URI, Path) :-
	uri_components(URI, uri_components(_,_,Path0,_,_)),
	atom_string(Path0, Path0_String),
	split_string(Path0_String, "/", "", Path_Components),
	append(_,[X],Path_Components), % get last item in list
	atomic_list_concat([Testcase, 'responses', X], "/", Relative_Path),
	catch(
		absolute_file_name(my_tests(Relative_Path), Path, []),
		_,
		true
	).

check_output_schema(Type, Response_XML_Path) :-
	%absolute_file_name(my_tmp(Response_XML_Path), Response_XML_Absolute_Path, []),
	(
		output_schema(Type, Schema_Relative_Path)
    ->
		(
			absolute_file_name(my_schemas(Schema_Relative_Path), Schema_Absolute_Path, []),
			validate_xml(Response_XML_Path, Schema_Absolute_Path, Schema_Errors),
			(
				Schema_Errors = []
			->
				true
			;
				(
					format("Errors: ~w~n", [Schema_Errors]),
					fail
				)
			)
		)
	;
		true
	).

/*
check_output_taxonomy(Type, Response_XML_Path) :-
	absolute_file_name(my_tmp(Response_XML_Path), Response_XML_Absolute_Path, []),
	(
		output_taxonomy(Type, Schema_Relative_Path)
    ->
		(
			absolute_file_name(my_static(Schema_Relative_Path), Schema_Absolute_Path, []),
			validate_xml(Response_XML_Absolute_Path, Schema_Absolute_Path, Schema_Errors),
			(
				Schema_Errors = []
			->
				true
			;
				(
					format("Errors: ~w~n", [Schema_Errors]),
					fail
				)
			)
		)
	;
		true
	).
*/

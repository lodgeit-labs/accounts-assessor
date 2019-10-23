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
:- use_module(library(xpath)).
:- use_module(library(readutil)).
:- use_module('../../lib/files').
:- use_module('../../lib/prolog_server').
:- use_module('compare_xml').
:- use_module('../../lib/utils', [
		floats_close_enough/2]).
:- use_module('../../lib/xml').


:- begin_tests(xml_testcases, [setup((debug,run_simple_server))]).

test(start) :- nl.

test(ledger, [forall(testcases('endpoint_tests/ledger',Testcase))]) :-
	run_endpoint_test(ledger, Testcase).

test(loan, [forall(testcases('endpoint_tests/loan',Testcase))]) :-
	run_endpoint_test(loan, Testcase).

test(depreciation, [forall(testcases('endpoint_tests/depreciation',Testcase))]) :-
	run_endpoint_test(depreciation, Testcase).

test(livestock, [forall(testcases('endpoint_tests/livestock',Testcase))]) :-
	run_endpoint_test(livestock, Testcase).

test(investment, [forall(testcases('endpoint_tests/investment', Testcase))]) :-
	run_endpoint_test(investment, Testcase).

test(car, [forall(testcases('endpoint_tests/car',Testcase)), fixme('NER API server is down.')]) :-
	run_endpoint_test(car, Testcase).

:- end_tests(xml_testcases).


output_schema(loan,'responses/LoanResponse.xsd').
output_schema(depreciation,'responses/DepreciationResponse.xsd').
output_schema(livestock,'responses/LivestockResponse.xsd').
output_schema(investment,'responses/InvestmentResponse.xsd').
output_schema(car,'responses/CarAPIResponse.xsd').

output_taxonomy(ledger,'taxonomy/basic.xsd').

run_endpoint_test(Type, Testcase) :-
	atomic_list_concat([Testcase, "request.xml"], "/", Request_XML_File_Path),

	query_endpoint(Request_XML_File_Path, Response_JSON),

	tmp_uri_to_path(Response_JSON.reports.response_xml.url, Response_XML_Path),
	check_output_schema(Type, Response_XML_Path),
%	check_output_taxonomy(Type, Response_XML_Path),

	% todo: xbrl validation on ledger response XBRL

	atomic_list_concat([Testcase, "responses/response.xml"], "/", Saved_Response_XML_File_Path),
	catch(
		absolute_file_name(my_tests(Saved_Response_XML_File_Path), Saved_Response_XML_Absolute_Path, []),
		_,
		true
	),



	(
		\+exists_file(Saved_Response_XML_Absolute_Path)
	->
		(
			print_alerts(Response_JSON, ['ERROR', 'WARNING', 'SYSTEM_WARNING']),
			Response_JSON.alerts = []
		)
	;
		(
			print_alerts(Response_JSON, ['SYSTEM_WARNING']),
			check_saved_response(Response_JSON, Request_XML_File_Path, Saved_Response_XML_Absolute_Path)
		)
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

check_saved_response(Response_JSON, Request_XML_File_Path, Saved_Response_XML_File_Path) :-
	/*
	todo: check all json files in the response, not just the response_xml
	*/
	http_get(Response_JSON.reports.response_xml.url, Response_XML, []),
	load_structure(string(Response_XML), Response_DOM,[dialect(xml),space(sgml)]),


	write('## Testing Response File: '), writeln(Saved_Response_XML_File_Path),
	test_response(nonloan, Response_DOM, Saved_Response_XML_File_Path).


check_value_difference(Value1, Value2) :-
	atom_number(Value1, NValue1),
	atom_number(Value2, NValue2),
	floats_close_enough(NValue1, NValue2).


test_response('endpoint_tests/loan', ReplyXML, LoanResponseFile0) :-
	test_loan_response(ReplyXML, LoanResponseFile0),
	test_response(general, ReplyXML, LoanResponseFile0),
	!.

test_response(_, Reply_Dom, Expected_Response_File_Absolute_Path) :-
	load_xml(Expected_Response_File_Absolute_Path, Expected_Reply_Dom, [space(sgml)]),
	compare_xml_dom(Reply_Dom, Expected_Reply_Dom, Error),
	(
		var(Error)
	->
		true
	;
		(
			get_flag(overwrite_response_files, true)
		->
			(
				open(Expected_Response_File_Absolute_Path, write, Stream),
				xml_write(Stream, Reply_Dom, []),
				close(Stream)
			)
		;
			(
				write_term("Error: ",[]),
				writeln(Error),
				writeln(""),
				fail
			)
		)
	).
	
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
if there's a "request.xml" file, it's a test-case directory, so yield it
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
	atomic_list_concat(Path_Components,"/",Path).


check_output_schema(Type, Response_XML_Path) :-
	absolute_file_name(my_tmp(Response_XML_Path), Response_XML_Absolute_Path, []),
	(
		output_schema(Type, Schema_Relative_Path)
    ->
		(
			absolute_file_name(my_schemas(Schema_Relative_Path), Schema_Absolute_Path, []),
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


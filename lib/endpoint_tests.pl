% ===================================================================
% Project:   LodgeiT
% Date:      2019-07-09
% ===================================================================
/*
this runs the requests in tests/endpoint_tests and compares the responses against saved files.
Note that the http server is spawned in this process. This should change in future.
*/

:- module(endpoint_tests, [setup/0,run_endpoint_test/2]).

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- use_module(library(debug), [assertion/1]).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_open)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json)).
:- use_module(library(xpath)).
:- use_module(library(readutil)).
:- use_module(library(xbrl/files), []).
:- use_module('prolog_server', []).
:- use_module('compare_xml').
:- asserta(user:file_search_path(library, '../prolog_xbrl_public/xbrl/prolog')).
:- use_module(library(xbrl/utils), []).
:- use_module(library(xbrl/files)).

:- multifile
	prolog:message//1.

prolog:message(testcase_error(Msg)) -->
	['test failed: ~w; ', [Msg] ].


setup :- debug,prolog_server:run_simple_server.

/* we run all the tests against the http server that we start in this process. This makes things a bit confusing. But the plan is to move to a python (or aws) gateway */
:- begin_tests(endpoints, [setup(setup)]).

test(start) :- nl.

test(testcase, []) :-
	current_prolog_flag(testcase, (Endpoint_Type, Testcase)),
	run_endpoint_test(Endpoint_Type, Testcase).

/*
hardcoded plunit test rules, one for each endpoint, so we can use things like "throws"
*/

test(sbe, []) :-
	http_post('http://localhost:8080/sbe', json(_{current_state:[]}), _, [content_type('application/json')]).

test(residency, []) :-
	http_post('http://localhost:8080/residency', json(_{current_state:[]}), _, [content_type('application/json')]).

test(ledger,
	[forall(testcases('endpoint_tests/ledger',Testcase))]) :-
	run_endpoint_test(ledger, Testcase).

test(loan, 
	[forall(testcases('endpoint_tests/loan',Testcase))]) :-
	run_endpoint_test(loan, Testcase).

test(livestock, 
	[forall(testcases('endpoint_tests/livestock',Testcase))]) :-
	run_endpoint_test(livestock, Testcase).

test(investment, 
	[forall(testcases('endpoint_tests/investment', Testcase))]) :-
	run_endpoint_test(investment, Testcase).

test(car, 
	[forall(testcases('endpoint_tests/car',Testcase)), fixme('NER API server is down.')]) :-
	run_endpoint_test(car, Testcase).

test(depreciation, 
	[forall(testcases('endpoint_tests/depreciation',Testcase))]) :-
	run_endpoint_test(depreciation, Testcase).

test(depreciation_invalid, 
	/* todo: the endpoint shouldnt die with a bad_request, it should return json with alerts, and we should simply check against a saved one */
	[forall(testcases('endpoint_tests/depreciation_invalid',Testcase)), throws(testcase_error(400))]) :-
	run_endpoint_test(depreciation_invalid, Testcase).

:- end_tests(endpoints).

/* mapping endpoints to response xsd files */
output_schema(loan,'responses/LoanResponse.xsd').
output_schema(depreciation,'responses/DepreciationResponse.xsd').
output_schema(livestock,'responses/LivestockResponse.xsd').
output_schema(investment,'responses/InvestmentResponse.xsd').
output_schema(car,'responses/CarAPIResponse.xsd').
output_taxonomy(ledger,'taxonomy/basic.xsd').

/* hmm maybe we should trust the endpoint to reference the right schema / do the validation? */

output_file(loan, 'response_xml', xml).
output_file(depreciation, 'response_xml', xml).
output_file(livestock, 'response_xml', xml).
output_file(investment, 'response_xml', xml).
output_file(car, 'response_xml', xml).
output_file(ledger, 'response_xml', xml).
output_file(ledger, 'general_ledger_json', json).
output_file(ledger, 'investment_report_json', json).
output_file(ledger, 'investment_report_since_beginning_json', json).


run_endpoint_test(Endpoint_Type, Testcase) :-
	debug(endpoint_tests, '(run_endpoint_test(~w, ~w)', [Endpoint_Type, Testcase]),
	run_endpoint_test2(Endpoint_Type, Testcase).

run_endpoint_test2(Endpoint_Type, Testcase) :-
	reset_gensym(iri), % because we use gensym in investment reports and it will keep incrementing throughout the test-cases, causing fresh responses to not match saved responses.
	query_endpoint(Testcase, Response_JSON),
	dict_pairs(Response_JSON.reports, _, Reports),
	maplist(check_returned(Endpoint_Type, Testcase), Reports, Errors),
	(	current_prolog_flag(grouped_assertions,true)
	->	(
			exclude(var, Errors, Errors2),
			flatten(Errors2, Errors3),
			assertion(Errors3 = [])
		)
	;	true).

	%					throw(testcase_error(Msg))
	%			format("Errors: ~w~n", [Error_List_Flat]),
	/*todo: all_saved_files(Testcase, Saved_Files),
	maplist(check_saved(Testcase, Reports), Saved_Files),*/
	

/*
check_saved(Testcase, Reports, Saved_File) :-
	reports_corresponding_to_saved(Testcase, Reports, Saved_File, Reports_Corresponding_To_Saved_File),
	(	Reports_Corresponding_To_Saved_File = [_]
	->	true % handled by check_returned
	;	(	Reports_Corresponding_To_Saved_File = []
		->	(	
				format('missing corresponding report file, saved file: ~w', [Saved_File]),
				throw('report missing')
			)
		;	throw('this is weird')
		)
	).
*/
check_returned(_, _, all-_, _) :- !. /* the report with the key "all" is a link to the directory with the report files */
check_returned(_, _, request_xml-_, _) :- !.

check_returned(Endpoint_Type, Testcase, Key-Report, Errors) :-
	tmp_uri_to_path(Report.url, Returned_Report_Path),
	tmp_uri_to_saved_response_path(Testcase, Report.url, Saved_Report_Path),
	(	\+exists_file(Saved_Report_Path)
	->	(
			get_flag(add_missing_response_files, true)
			->	copy_report_to_saved(Returned_Report_Path, Saved_Report_Path)
			;	(
					format(string(Msg), 'file contained in response is not found in saved files.', []),
					writeln(Msg),
					offer_cp(Returned_Report_Path, Saved_Report_Path),
					Errors = [Msg]
				)
		)
	;	check_saved_report0(Endpoint_Type, Key, Returned_Report_Path, Saved_Report_Path, Errors)
	).

offer_cp(Src, Dst) :-
	atomics_to_string(['/bin/cp "', Src, '" "', Dst, '"'], Cmd),
	atomics_to_string(['http://localhost:8000/shell/?cmd=',Cmd], Url),
	utils:print_clickable_link(Url, Cmd).


check_saved_report0(Endpoint_Type, Key, Returned_Report_Path, Saved_Report_Path, Errors) :-
	file_type_by_extension(Returned_Report_Path, File_Type),
	check_saved_report1(Endpoint_Type, Returned_Report_Path, Saved_Report_Path, Key, File_Type, Errors),
	(current_prolog_flag(grouped_assertions,true)
	->	true
	;	assertion(Errors = [])),
	(	Errors = []
	->	true
	;	(
			(	get_flag(overwrite_response_files, true)
			->	copy_report_to_saved(Returned_Report_Path, Saved_Report_Path)
			;	(	current_prolog_flag(move_on_after_first_error,true)
				->	throw(testcase_error(Errors))
				;	true)
			)
		)
	).
	

check_saved_report1(Endpoint_Type, Returned_Report_Path, Saved_Report_Path, Key, File_Type, Errors) :-
	debug(endpoint_tests, '~n## ~q: ~n', [check_saved_report1(Endpoint_Type, Returned_Report_Path, Saved_Report_Path, Key, File_Type, Errors)]),
	test_response(Endpoint_Type, Returned_Report_Path, Saved_Report_Path, Key, File_Type, Errors0),
	findall(Key:Error, member(Error,Errors0), Errors).


test_response(Endpoint_Type, Returned_Report_Path, Saved_Report_Path, Key, xml, Errors) :-
	!,
	load_structure(Returned_Report_Path, Response_DOM, [dialect(xml),space(sgml)]),
	check_output_schema(Endpoint_Type, Key, Returned_Report_Path),
	% todo: xbrl validation on ledger response XBRL
	%check_output_taxonomy(Endpoint_Type, Response_XML_Path),
	load_xml(Saved_Report_Path, Saved_Response_DOM, [space(sgml)]),
	compare_xml_dom(Response_DOM, Saved_Response_DOM, Error),
	(
		var(Error)
	->
		Errors = []
	;
		(
			Errors = [Error|Errors2],
			diff_service(Saved_Report_Path, Returned_Report_Path, Errors2)
		)
	).

test_response(_, Returned_Report_Path, Saved_Report_Path, _Key, json, Errors) :-
	diff_service(Saved_Report_Path, Returned_Report_Path, Errors).


test_response(_, Returned_Report_Path, Saved_Report_Path, _, _, Error) :-
	(	diff(Saved_Report_Path, Returned_Report_Path, true)
	->	Error = []
	;	Error = ['files differ']).


/* todo replace xmldiff, it doesnt return status and the diff seem useless
			we are focusing on just diffing our particular variety of xmls, that is:
				any text is irrelevant unless it has no sibling nodes
				comments should be disregarded
			and disregarding the philosophical problem that without following an xsd, it's impossible to tell if some text is supposed to be a number (and should thus be compared a float error tolerance
			best bet: take one of the parsers wrapped by defusedxml, possibly pre-process the output into maybe dicts,
			with irrelevant text cleaned out, and pass to deepdiff
			With htmls, this wont work, so possibly jusst deepdiff without the pre-cleanup, or just textual diff
			Anyway, it maybe makes more sense to focus on having a json of each report, with just the semantially significant bits, and focus on checking those, possibly ignoring the lesser formats entirely
*/

/*			diff2(Saved_Report_Path, Returned_Report_Path, _, [cmd(['../python/venv/bin/python3','../python/src/structural_xmldiff.py'])]),
			format(/*user_error, */'~n^^that was deepdiff ~w ~w~n', [Saved_Report_Path, Returned_Report_Path]),
			offer_cp(Returned_Report_Path, Saved_Report_Path),
*/

diff_service(Saved_Report_Path, Returned_Report_Path, Errors) :-
	utils:float_comparison_significant_digits(D),
	atomics_to_string([
		'http://localhost:8000/json_diff/',
		'?a=',Saved_Report_Path,
		'&b=',Returned_Report_Path,
		'&options={"significant_digits":',D,'}'
		], Request_URI),
	catch(
		(
			(
				setup_call_cleanup(
					rq(Request_URI, Response_Stream),
					read_string(Response_Stream, _, Response_String),
					close(Response_Stream)
				),
				utils:string_to_json(Response_String, _{diff:Diff,msg:Msg})
			),
			(	Diff = _{}
			->	Errors = []
			;	(
					Errors = ['files differ'],
					nl,nl,
					(	Msg \= ""
					->	writeln(Msg)
					;	writeln(Response_String)),
					nl,nl,
					format(/*user_error, */'~n^^that was diff_service ~w ~w~n', [Saved_Report_Path, Returned_Report_Path]),
					offer_cp(Returned_Report_Path, Saved_Report_Path)
				)
			)
		),
		E,
		(
			term_string(E, E_Str),
			Errors = [E_Str]
		)
	).

rq(Request_URI, Response_Stream) :- http_open:http_open(Request_URI, Response_Stream, [request_header('Accept'='application/json')]).


diff(Saved_Report_Path, Returned_Report_Path, Are_Same) :-
	diff2(Saved_Report_Path, Returned_Report_Path, Are_Same, [cmd(diff)]).

diff2(Saved_Report_Path, Returned_Report_Path, Are_Same, Options) :-
	memberchk(cmd(Executable), Options),
	utils:shell3([Executable, Saved_Report_Path, Returned_Report_Path], [exit_status(Exit_Status), command(Cmdline)]),
	(	Exit_Status = 0
	->	Are_Same = true
	;	(
			format(/*user_error, */'~n^^that was ~w~n', [Cmdline]),
			offer_cp(Returned_Report_Path, Saved_Report_Path),
			Are_Same = false % this must be the last statement
		)
	).
	%awk -v len=40 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }'

reports_corresponding_to_saved(Testcase, Reports, Saved_File, Reports_Corresponding_To_Saved_File) :-
	findall(
		Report,
		(
			member(Report, Reports),
			tmp_uri_to_saved_response_path(Testcase, Report.url, Saved_File)
		),
		Reports_Corresponding_To_Saved_File
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
	utils:floats_close_enough(NValue1, NValue2).

query_endpoint(Testcase, Response_JSON) :-
	debug(endpoint_tests, '~n## Testing Request: ~w', [Testcase]),

	absolute_file_name(my_tests(Testcase),Testcase_Directory_Path, [ access(read), file_type(directory) ]),
	files:directory_real_files(Testcase_Directory_Path, File_Paths),
	findall(
		file=file(RequestFile),
		member(RequestFile, File_Paths),
		File_Form_Entries),
	catch(
		http_post('http://localhost:8080/upload?requested_output_format=json_reports_list', form_data(File_Form_Entries), Response_String, [content_type('multipart/form-data')]),
		error(existence_error(_,_),_),
		throw(testcase_error(400))
	),
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
	debug(endpoint_tests, "testcases: ~w~n", [Top_Level]),
	find_test_cases_in(Top_Level, Testcase).

/*
if there's a "request.xml" file, it's a test-case directory, so yield it,
otherwise, recurse over subdirectories
*/

find_test_cases_in(Current_Directory, Test_Case) :-
	absolute_file_name(my_tests(Current_Directory), Current_Directory_Absolute, [file_type(directory)]),
	files:directory_entries(Current_Directory_Absolute, Entries),
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
	files:absolute_whatever(my_tmp(Relative_Path), Path).


tmp_uri_to_saved_response_path(Testcase, URI, Path) :-
	uri_components(URI, uri_components(_,_,Path0,_,_)),
	atom_string(Path0, Path0_String),
	split_string(Path0_String, "/", "", Path_Components),
	last(Path_Components, X), % get last item in list
	atomic_list_concat([Testcase, 'responses', X], "/", Relative_Path),
	files:absolute_whatever(my_tests(Relative_Path), Path).



check_output_schema(Endpoint_Type, Key, Response_XML_Path) :-
	(
		(
			output_file(Endpoint_Type, Key, xml),
			output_schema(Endpoint_Type, Schema_Relative_Path)
		)
	->
		(
			absolute_file_name(my_schemas(Schema_Relative_Path), Schema_Absolute_Path, []),
			utils:validate_xml(Response_XML_Path, Schema_Absolute_Path, Schema_Errors),
			(
				Schema_Errors = []
			->
				true
			;
				format("Errors: ~w~n", [Schema_Errors])
			)
		)
	;
		true
	).

copy_report_to_saved(R, S) :-
	directory_file_path(D, _, S),
	make_directory_path(D),
	copy_file(R,S).

file_type_by_extension(Returned_Report_Path, File_Type) :-
	string_lower(Returned_Report_Path, P),
	split_string(P, ".", ".", List),
	last(List, Last),
	atom_string(File_Type, Last),
	!.

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

%			print_alerts(Response_JSON, ['ERROR', 'WARNING', 'SYSTEM_WARNING']),
			/* if we have no saved xml response, and there are alerts in the json, fail the test */
			/*Response_JSON.alerts = []*/
%			fail


	%print_alerts(Response_JSON, ['SYSTEM_WARNING']),

%	http_get(Response_URL, Response_XML, []),

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

:- begin_tests(xml_testcases, [setup((debug,run_simple_server))]).

test(start) :- nl.

test(invalid, throws(_)) :-
/*
	todo: probably all invalid request files should have a corresponding response file, where a xml-formatted error message is. The endpoint should probably still answer with a Bad Request status code, but we should catch it in query_endpoint and parse the error xml. If the invalid requests are stored in invalid/, we just nedd to change the file search algo to list all sub-directories recursively.
*/
	query_endpoint('endpoint_tests/depreciation/invalid/depreciation-request-written-down-values-earlier-reuqest-date-invalid.xml', _).

test(endpoints, [forall(testcases(Testcase))]) :-
	run_endpoint_test(Testcase).

:- end_tests(xml_testcases).

run_endpoint_test(Testcase) :-
	format("run_endpoint_tests; test-case: ~w~n",[Testcase]),
	%Testcase = (Request_XML_File_Path, Response),
	/* todo: each test-case should get its own directory
			* request.xml
			* responses/
	*/
	
	atomic_list_concat([Testcase, "request.xml"], "/", Request_XML_File_Path),

	query_endpoint(Request_XML_File_Path, Response_JSON),

	% check for error messages
	% Response_Errors = Response_JSON.alerts
	% Response_JSON.alerts = [_], % there is an error

	http_get(Response_JSON.reports.response_xml.url, Response_XML, []),
	find_warnings(Response_XML),
	load_structure(string(Response_XML), Response_DOM,[dialect(xml),space(sgml)]),


	atomic_list_concat([Testcase, "responses/response.xml"], "/", Saved_Response_XML_File_Path),
	absolute_file_name(Saved_Response_XML_File_Path, Saved_Response_XML_Absolute_Path, []),
	

	(
		%var(Response)
		\+exists_file(Saved_Response_XML_Absolute_Path)
	->
		(
			true
	
			/*
			todo: we have no known response file, we should check if the actual response is an error xml and fail if it is
			*/
	
		)
			
	;
		(
			write('## Testing Response File: '), writeln(Saved_Response_XML_File_Path),
			%get_request_context(Request_XML_File_Path, Context),
			test_response(nonloan, Response_DOM, Saved_Response_XML_Absolute_Path)
		)
	).

	% todo: validate other json docs.

check_value_difference(Value1, Value2) :-
	atom_number(Value1, NValue1),
	atom_number(Value2, NValue2),
	floats_close_enough(NValue1, NValue2).


test_response(loan, ReplyXML, LoanResponseFile0) :-
	test_loan_response(ReplyXML, LoanResponseFile0),
	test_response(general, ReplyXML, LoanResponseFile0),
	!.

test_response(_, Reply_Dom, /*Expected_Response_File_Relative_Path*/ Expected_Response_File_Absolute_Path) :-
	/*
	absolute_file_name(my_tests(
		Expected_Response_File_Relative_Path),
		Expected_Response_File_Absolute_Path,
		[ access(read) ]
	),
	*/
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

	%writeln("Before json_read_dict"),
    %json_read_dict(Response_String, Response_JSON_Raw),
    atom_json_dict(Response_String, Response_JSON_Raw,[value_string_as(atom)]),
	%writeln("After json_read_dict"),
	% transform Response_JSON_Raw into Response_JSON
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

find_warnings(ReplyXML) :-
	atom_string(ReplyXML, ReplyXML2),
	split_string(ReplyXML2, '\n', '\n', Lines),
	maplist(echo_warning_line, Lines).

echo_warning_line(Line) :-
	(
		sub_string(Line, _, _, _, 'SYSTEM_WARNING')
	->
		format(user_error, '~w\n', [Line])
	;
		true
	).
testcases(Testcase) :-
	find_test_cases_in('endpoint_tests', Testcase).

% it's a test-case directory if there's a request.xml file, otherwise it's a regular directory
% if it's a test-case directory, yield it
% if it's a regular directory, recurse over subdirectories

find_test_cases_in(Current_Directory, Test_Case) :-
	%format("Current directory: ~w~n", [Current_Directory]),
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
			%format("Subdirectory: ~w~n", [Subdirectory_Relative_Path]),
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



testcases(Testcase) :-
	find_test_directories(Paths),
	member(Path, Paths),
	find_requests(Path, Testcases),
	member(Testcase, Testcases).

find_test_directories(Paths) :-
	Top_Level_Directory = 'endpoint_tests',
	absolute_file_name(my_tests(Top_Level_Directory), Endpoint_Tests_Path, [file_type(directory)]),
	directory_files(Endpoint_Tests_Path, Entries),
	findall(Relative_Path,
		(
			member(Directory, Entries),
			\+sub_atom_icasechk(Directory, _Start, '.'),
			atomic_list_concat([Top_Level_Directory, '/', Directory], Relative_Path),
			atomic_list_concat([Endpoint_Tests_Path, '/', Directory], Absolute_Path),
			exists_directory(Absolute_Path)
		),
		Paths
	).

find_requests(Path, Testcases) :-
	absolute_file_name(my_tests(Path), Full_Path, [file_type(directory)]),
	directory_files(Full_Path, Entries),
	include(is_request_file, Entries, Requests0),
	sort(Requests0, Requests),
	findall(
		(Request_Path, Response_Path),
		(
			member(Request, Requests),
			atomic_list_concat([Path, '/', Request], Request_Path),
			response_file(Request_Path, Response_Path)
		),
		Testcases
	).

is_request_file(Atom) :-
	atom_concat(_,'.xml',Atom),
	sub_atom_icasechk(Atom, _Start2, 'request').

response_file(Atom, Response) :-
	replace_request_with_response(Atom, Response),
	absolute_file_name(my_tests(Response),_,[ access(read), file_errors(fail) ]),
	!.

response_file(_, _).
	
% find the subdirectory of endpoint_tests that this request file is in
/*
get_request_context(Request, Context) :-
	atom_chars(Request, RequestChars),
	once(append(['e','n','d','p','o','i','n','t','_','t','e','s','t','s','/' | ContextChars], ['/' | _], RequestChars)),
	atomic_list_concat(ContextChars, Context).
*/
	
/* 
loan endpoint specific testing. General xml comparison should handle it just fine, but let's leave it here as an example for when endpoint-specific testing actually is necessary
*/
	
test_loan_response(ActualReplyDOM, Expected_LoanResponseFile0) :-
	
	absolute_file_name(my_tests(
		Expected_LoanResponseFile0),
		Expected_LoanResponseFile,
		[ access(read) ]
	),
	
	load_xml(Expected_LoanResponseFile, ExpectedReplyDOM, [space(sgml)]),

	% do the comparison here?	
	% seems fine to me

	extract_loan_response_values(ActualReplyDOM, ActualIncomeYear, ActualOpeningBalance, ActualInterestRate, ActualMinYearlyRepayment, ActualTotalRepayment, 
		ActualRepaymentShortfall, ActualTotalInterest, ActualTotalPrincipal, ActualClosingBalance),
	
	extract_loan_response_values(ExpectedReplyDOM, ExpectedIncomeYear, ExpectedOpeningBalance, ExpectedInterestRate, ExpectedMinYearlyRepayment, ExpectedTotalRepayment, 
		ExpectedRepaymentShortfall, ExpectedTotalInterest, ExpectedTotalPrincipal, ExpectedClosingBalance),

	assertion(check_value_difference(ActualIncomeYear, ExpectedIncomeYear)),
	assertion(check_value_difference(ActualOpeningBalance, ExpectedOpeningBalance)),
	assertion(check_value_difference(ActualInterestRate, ExpectedInterestRate)),
	assertion(check_value_difference(ActualMinYearlyRepayment, ExpectedMinYearlyRepayment)),
	assertion(check_value_difference(ActualTotalRepayment, ExpectedTotalRepayment)),
	assertion(check_value_difference(ActualRepaymentShortfall, ExpectedRepaymentShortfall)),
	assertion(check_value_difference(ActualTotalInterest, ExpectedTotalInterest)),
	assertion(check_value_difference(ActualTotalPrincipal, ExpectedTotalPrincipal)),
	assertion(check_value_difference(ActualClosingBalance, ExpectedClosingBalance)).

% -------------------------------------------------------------------
% Extract all required information from the loan response XML
% -------------------------------------------------------------------

extract_loan_response_values(DOM, IncomeYear, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment, RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance) :-
	findall(
		x,
		extract_loan_response_values2(DOM, IncomeYear, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment, RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance),
		[x]),
	once(extract_loan_response_values2(DOM, IncomeYear, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment, RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance)).

		
extract_loan_response_values2(DOM, IncomeYear, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment, RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance) :-
	xpath(DOM, //'LoanSummary'/'IncomeYear', element(_, _, [IncomeYear])),
	xpath(DOM, //'LoanSummary'/'OpeningBalance', element(_, _, [OpeningBalance])),
	xpath(DOM, //'LoanSummary'/'InterestRate', element(_, _, [InterestRate])),
	xpath(DOM, //'LoanSummary'/'MinYearlyRepayment', element(_, _, [MinYearlyRepayment])),
	xpath(DOM, //'LoanSummary'/'TotalRepayment', element(_, _, [TotalRepayment])),
	xpath(DOM, //'LoanSummary'/'RepaymentShortfall', element(_, _, [RepaymentShortfall])),
	xpath(DOM, //'LoanSummary'/'TotalInterest', element(_, _, [TotalInterest])),
	xpath(DOM, //'LoanSummary'/'TotalPrincipal', element(_, _, [TotalPrincipal])),
	xpath(DOM, //'LoanSummary'/'ClosingBalance', element(_, _, [ClosingBalance])).
	
/*
end loan stuff
*/


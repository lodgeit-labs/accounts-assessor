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
:- use_module(library(xpath)).
:- use_module('../../lib/files').
:- use_module('../../prolog_server/prolog_server').
:- use_module('compare_xml').
:- use_module('../../lib/utils', [floats_close_enough/2]).

:- begin_tests(xml_testcases, [setup(run_simple_server)]).

test(start) :- nl.

test(endpoints, [forall(testcases(Testcase))]) :-
	Testcase = (Request, Response),
	query_endpoint(Request, ReplyDOM),
	(
		var(Response)
	->
		true
	;
		(
			write('## Testing Response File: '), writeln(Response),
			get_request_context(Request, Context),
			test_response(Context, ReplyDOM, Response)
		)
	).

:- end_tests(xml_testcases).


check_value_difference(Value1, Value2) :-
	atom_number(Value1, NValue1),
	atom_number(Value2, NValue2),
	floats_close_enough(NValue1, NValue2).


test_response(loan, ReplyXML, LoanResponseFile0) :-
	test_loan_response(ReplyXML, LoanResponseFile0),
	test_response(general, ReplyXML, LoanResponseFile0),
	!.

test_response(_, Reply_Dom, Expected_Response_File_Relative_Path) :-
	absolute_file_name(my_tests(
		Expected_Response_File_Relative_Path),
		Expected_Response_File_Absolute_Path,
		[ access(read) ]
	),
	load_xml(Expected_Response_File_Absolute_Path, Expected_Reply_Dom, [space(sgml)]),
	compare_xml_dom(Reply_Dom, Expected_Reply_Dom,Error),
	(
		var(Error)
	->
		true
	;
		(
			write_term("Error: ",[]),
			writeln(Error),
			writeln(""),
			fail
		)
	).
	
query_endpoint(RequestFile0, ReplyDOM) :-
	write('## Testing Request File: '), writeln(RequestFile0),
	absolute_file_name(my_tests(
		RequestFile0),
		RequestFile,
		[ access(read) ]
	),
	http_post('http://localhost:8080/upload', form_data([file=file(RequestFile)]), ReplyXML, [content_type('multipart/form-data')]),
	load_structure(string(ReplyXML), ReplyDOM,[dialect(xml),space(sgml)]).
	
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
	atom_string(Atom, String),
	(
		(
			re_replace('request', 'response', String, Response);
			re_replace('Request', 'Response', String, Response);
			re_replace('REQUEST', 'RESPONSE', String, Response)
		),
		String \= Response
	),
	absolute_file_name(my_tests(Response),_,[ access(read), file_errors(fail) ]),
	!.

response_file(_, _).
	
% find the subdirectory of endpoint_tests that this request file is in
get_request_context(Request, Context) :-
	atom_chars(Request, RequestChars),
	once(append(['e','n','d','p','o','i','n','t','_','t','e','s','t','s','/' | ContextChars], ['/' | _], RequestChars)),
	atomic_list_concat(ContextChars, Context).

	
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

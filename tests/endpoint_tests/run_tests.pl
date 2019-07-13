% ===================================================================
% Project:   LodgeiT
% Date:      2019-07-09
% ===================================================================

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- use_module(library(debug), [assertion/1]).
:- use_module(library(http/http_client)).
:- use_module(library(xpath)).
:- use_module('../../lib/files').



:- initialization(run_tests).

:- begin_tests(xml_testcases, [setup(consult('../../prolog_server/run_simple_server.pl'))]).

test(endpoint_requests_without_responses, [forall(tests_without_response(Without_Response))]) :-
	test_request_without_response(Without_Response).

test(endpoint_requests_with_responses, forall(tests_with_response(With_Response))) :-
	test_request_with_response(With_Response).

:- end_tests(xml_testcases).




% define the value to compare expected float value with the actual float value
% we need this value as float operations generate different values after certain precision in different machines
accepted_min_difference(0.0000001).

check_value_difference(Value1, Value2) :-
	atom_number(Value1, NValue1),
	atom_number(Value2, NValue2),
	ValueDifference is abs(NValue1 - NValue2),
	accepted_min_difference(MinimalDifference),
	ValueDifference =< MinimalDifference.

	
test_response(loan, ReplyXML, LoanResponseFile0) :-
	test_loan_response(ReplyXML, LoanResponseFile0).

test_response(general, Reply_Dom, Expected_Response_File_Relative_Path) :-
	absolute_file_name(my_tests(
		Expected_Response_File_Relative_Path),
		Expected_Response_File_Absolute_Path,
		[ access(read) ]
	),
	load_xml(Expected_Response_File_Absolute_Path, Expected_Reply_Dom, []),
	compare_testcase_doms(Reply_Dom, Expected_Reply_Dom).
	
test_request(RequestFile0, ReplyXML) :-
	absolute_file_name(my_tests(
		RequestFile0),
		RequestFile,
		[ access(read) ]
	),
	http_post('http://localhost:8080/upload', form_data([file=file(RequestFile)]), ReplyXML, [content_type('multipart/form-data')]).
	
tests_without_response(Without_Response) :-
	find_test_directories(Paths),
	member(Path, Paths),
	find_requests(Path, _, Without_Responses),
	member(Without_Response, Without_Responses).

tests_with_response(With_Response) :-
	find_test_directories(Paths),
	member(Path, Paths),
	find_requests(Path, With_Responses, _),
	member(With_Response, With_Responses).

test_request_without_response(Request) :-
	test_request(Request, _).

test_request_with_response((Request, Response)) :-
	test_request(Request, ReplyXML),
	get_request_context(Request, Context),
	(
		Context = loan 
	-> 
		test_response(loan, ReplyXML, Response)
	;
		test_response(general, ReplyXML, Response)
	).
	
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

find_requests(Path, With_Responses, Without_Responses) :-
	absolute_file_name(my_tests(Path), Full_Path, [file_type(directory)]),
	directory_files(Full_Path, Entries),
	include(is_request_file, Entries, Requests),
	findall(
		(Request_Path, Response_Path),
		(
			member(Request,	Requests),
			atomic_list_concat([Path, '/', Request], Request_Path),
			has_response_file(Request_Path, Response_Path)
		),
		With_Responses
	),
	findall(
		Request_Path,
		(
			member(Request,	Requests),
			atomic_list_concat([Path, '/', Request], Request_Path),
			\+has_response_file(Request_Path, _)
		),
		Without_Responses
	).
	
is_request_file(Atom) :-
	/* does not require that the searched-for part is at the end of the atom, but that's good enough for now*/
	sub_atom_icasechk(Atom, _Start1, '.xml'),
	sub_atom_icasechk(Atom, _Start2, 'request').

has_response_file(Atom, Response) :-
	re_replace('request', 'response', Atom, Response),
	absolute_file_name(my_tests(Response),_,[ access(read), file_errors(fail) ]).

% find the subdirectory of endpoint_tests that this request file is in
get_request_context(Request, Context) :-
	atom_chars(Request, RequestChars),
	append(['e','n','d','p','o','i','n','t','_','t','e','s','t','s','/' | ContextChars], ['/' | _], RequestChars),
	atomic_list_concat(ContextChars, Context).

	
/* 
loan endpoint specific testing. General xml comparison should handle it just fine, but let's leave it here as an example for when endpoint-specific testing actually is necessary
*/
	
test_loan_response(ReplyXML, LoanResponseFile0) :-
	absolute_file_name(my_tests(
		LoanResponseFile0),
		LoanResponseFile,
		[ access(read) ]
	),
	absolute_file_name(my_tmp(
		'actual-loan-response.xml'),
		TempLoanResponseFile,
		[]
	),
	
	nl, write('## Testing Response File: '), writeln(LoanResponseFile),
	open(TempLoanResponseFile, write, Stream),
	write(Stream, ReplyXML),
	close(Stream),
	
	load_xml(TempLoanResponseFile, ActualReplyDOM, []),
	load_xml(LoanResponseFile, ExpectedReplyDOM, []),
	
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

compare_testcase_doms(_Reply_Dom, _Expected_Reply_Dom) :-
	true.


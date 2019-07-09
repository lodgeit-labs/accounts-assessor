% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_loan_request_test.pl
% Date:      2019-07-09
% ===================================================================

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- use_module(library(debug), [assertion/1]).
:- use_module(library(http/http_client)).
:- use_module(library(xpath)).
:- use_module('../../lib/files').


% -------------------------------------------------------------------
% Test Codes
% -------------------------------------------------------------------

:- begin_tests(process_xml_loan_request, [setup(consult('../../prolog_server/run_simple_server.pl'))]).

% define the value to compare expected float value with the actual float value
% we need this value as float operations generate different values after certain precision in different machines
accepted_min_difference(0.0000001).

check_value_difference(Value1, Value2) :-
	atom_number(Value1, NValue1),
	atom_number(Value2, NValue2),
	ValueDifference is NValue1 - NValue2,

	accepted_min_difference(MinimalDifference),
	(ValueDifference =< MinimalDifference ; ValueDifference >= MinimalDifference).

% -------------------------------------------------------------------
% Test the loan request and response values for the given files given
% The list in the first argument contains the paths of the loan 
% request files and the second argument do so for loan response files
% -------------------------------------------------------------------

test_loan_response([], _).
test_loan_response([LoanRequestFile0 | LoanRequestFileList], [LoanResponseFile0 | LoanResponseFileList]) :-
	
	test_request(LoanRequestFile0, ReplyXML),
	test_response(loan, ReplyXML, LoanResponseFile0),
	
	test_loan_response(LoanRequestFileList, LoanResponseFileList).

test_response(loan, ReplyXML, LoanResponseFile0) :-
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

test_request(RequestFile0, ReplyXML) :-

	absolute_file_name(my_tests(
		RequestFile0),
		RequestFile,
		[ access(read) ]
	),
	
	nl, write('>> Testing Request File: '), writeln(RequestFile),

	(
		catch(
			http_post('http://localhost:8080/upload', form_data([file=file(RequestFile)]), ReplyXML, [content_type('multipart/form-data')]),
		E,
		(
			format(user_error, '~w', [E]),
			fail
		))).

	
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



% -------------------------------------------------------------------
% call the 'test_loan_request' predicate with the loan request and
% response files in the arguments.
% whenever we have a new request/response values that we want to 
% test, we can add the request file in the list of the first argument
% and add the response file in the list of the second argument
% -------------------------------------------------------------------

test(loan_request) :-

	test_loan_response(['endpoint_tests/loan/loan-request1.xml', 
						'endpoint_tests/loan/loan-request2.xml', 
						'endpoint_tests/loan/loan-request3.xml', 
						'endpoint_tests/loan/loan-request4.xml', 
						'endpoint_tests/loan/loan-request5.xml', 
						'endpoint_tests/loan/loan-request6.xml'
					  ],
					  ['endpoint_tests/loan/loan-response1.xml', 
						'endpoint_tests/loan/loan-response2.xml', 
						'endpoint_tests/loan/loan-response3.xml', 
						'endpoint_tests/loan/loan-response4.xml', 
						'endpoint_tests/loan/loan-response5.xml', 
						'endpoint_tests/loan/loan-response6.xml']).
						

test(endpoint) :-

	find_test_directories(Directories),
	maplist(test_directory, Directories).

test_directory(Path) :-
	find_requests(Path, With_Responses, Without_Responses),
	maplist(test_request_with_response, With_Responses),	
	maplist(test_request_without_response, Without_Responses).

test_request_without_response(Request) :-
	test_request(Request, _).

test_request_with_response((Request, Response)) :-
	/*general xml comparison with Response, todo*/
	test_request(Request, ReplyXML),
	get_request_context(Request, Context),
	(Context = loan -> test_response(loan, ReplyXML, Response) ; true).

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

% find the context from the path based on the directory name
get_request_context(Request, Context) :-
	atom_chars(Request, RequestChars),
	append(['e','n','d','p','o','i','n','t','_','t','e','s','t','s','/' | ContextChars], ['/' | Rest], RequestChars),
	atomic_list_concat(ContextChars, Context).

:- end_tests(process_xml_loan_request).

:- initialization(run_tests).


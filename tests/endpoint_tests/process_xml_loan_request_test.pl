% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_loan_request_test.pl
% Date:      2019-07-08
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

% -------------------------------------------------------------------
% Test the loan request and response values for the given files given
% The list in the first argument contains the paths of the loan 
% request files and the second argument do so for loan response files
% -------------------------------------------------------------------

test_loan_request([], _).
test_loan_request([LoanRequestFile0 | LoanRequestFileList], [LoanResponseFile0 | LoanResponseFileList]) :-
	
	absolute_file_name(my_tests(
		LoanRequestFile0),
		LoanRequestFile,
		[ access(read) ]
	),
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
	
	nl, write('>> Testing Loan Request File: '), writeln(LoanRequestFile),
	
	http_post('http://localhost:8080/upload', form_data([file=file(LoanRequestFile)]), ReplyXML, [content_type('multipart/form-data')]),
	
	open(TempLoanResponseFile, write, Stream),
	write(Stream, ReplyXML),
	close(Stream),
	
	load_xml(TempLoanResponseFile, ActualReplyDOM, []),
	load_xml(LoanResponseFile, ExpectedReplyDOM, []),
	
	extract_loan_response_values(ActualReplyDOM, ActualOpeningBalance, ActualInterestRate, ActualMinYearlyRepayment, ActualTotalRepayment, 
		ActualRepaymentShortfall, ActualTotalInterest, ActualTotalPrincipal, ActualClosingBalance),
		
	extract_loan_response_values(ExpectedReplyDOM, ExpectedOpeningBalance, ExpectedInterestRate, ExpectedMinYearlyRepayment, ExpectedTotalRepayment, 
		ExpectedRepaymentShortfall, ExpectedTotalInterest, ExpectedTotalPrincipal, ExpectedClosingBalance),
	
	assertion(ActualOpeningBalance == ExpectedOpeningBalance),
	assertion(ActualInterestRate == ExpectedInterestRate),
	assertion(ActualMinYearlyRepayment == ExpectedMinYearlyRepayment),
	assertion(ActualTotalRepayment == ExpectedTotalRepayment),
	assertion(ActualRepaymentShortfall == ExpectedRepaymentShortfall),
	assertion(ActualTotalInterest == ExpectedTotalInterest),
	assertion(ActualTotalPrincipal == ExpectedTotalPrincipal),
	assertion(ActualClosingBalance == ExpectedClosingBalance),
	
	test_loan_request(LoanRequestFileList, LoanResponseFileList).

	
% -------------------------------------------------------------------
% Extract all required information from the loan response XML
% -------------------------------------------------------------------

extract_loan_response_values(DOM, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment, RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance) :-
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
	test_loan_request(['endpoint_tests/loan/loan-request1.xml', 
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
						
:- end_tests(process_xml_loan_request).

:- run_tests.

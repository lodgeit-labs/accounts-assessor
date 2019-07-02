% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_loan_request_test.pl
% Date:      2019-07-02
% ===================================================================

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- use_module(library(debug), [assertion/1]).
:- use_module(library(http/http_client)).
:- use_module(library(xpath)).


% -------------------------------------------------------------------
% Test Codes
% Please read "README.txt" file in the current directory to 
% understand the file operations.
%
% We have to update the schema and request/response files in
% the 'taxonomy' and 'tmp' folder in the current directory 
% if there is any modification.
% -------------------------------------------------------------------


:- begin_tests(process_xml_loan_request, [setup(consult('../../prolog_server/run_simple_server.pl'))]).

test(loan_request) :-
	LoanRequestFile = 'loan/loan-request1.xml',
	LoanResponseFile = 'loan/loan-response1.xml',
	TempLoanResponseFile = './tmp/actual-loan-response.xml',
	
	http_post('http://localhost:8080/upload', form_data([file=file(LoanRequestFile)]), ReplyXML, [content_type('multipart/form-data')]),
	
	
	open(TempLoanResponseFile, write, Stream),
	write(Stream, ReplyXML),
	close(Stream),
	
	load_xml(TempLoanResponseFile, ActualReplyDOM, []),
	load_xml(LoanResponseFile, ExpectedReplyDOM, []),
	
	LoanSummaryNode = 'LoanSummary',
	OpeningBalanceNode = 'OpeningBalance',
	InterestRateNode = 'InterestRate',
	MinYearlyRepaymentNode = 'MinYearlyRepayment',
	TotalRepaymentNode = 'TotalRepayment',
	RepaymentShortfallNode = 'RepaymentShortfall',
	TotalInterestNode = 'TotalInterest',
	TotalPrincipalNode = 'TotalPrincipal',
	ClosingBalanceNode = 'ClosingBalance',
	
	xpath(ActualReplyDOM, //LoanSummaryNode/OpeningBalanceNode, element(_, _, [ActualOpeningBalance])),
	xpath(ActualReplyDOM, //LoanSummaryNode/InterestRateNode, element(_, _, [ActualInterestRate])),
	xpath(ActualReplyDOM, //LoanSummaryNode/MinYearlyRepaymentNode, element(_, _, [ActualMinYearlyRepayment])),
	xpath(ActualReplyDOM, //LoanSummaryNode/TotalRepaymentNode, element(_, _, [ActualTotalRepayment])),
	xpath(ActualReplyDOM, //LoanSummaryNode/RepaymentShortfallNode, element(_, _, [ActualRepaymentShortfall])),
	xpath(ActualReplyDOM, //LoanSummaryNode/TotalInterestNode, element(_, _, [ActualTotalInterest])),
	xpath(ActualReplyDOM, //LoanSummaryNode/TotalPrincipalNode, element(_, _, [ActualTotalPrincipal])),
	xpath(ActualReplyDOM, //LoanSummaryNode/ClosingBalanceNode, element(_, _, [ActualClosingBalance])),
	
	xpath(ExpectedReplyDOM, //LoanSummaryNode/OpeningBalanceNode, element(_, _, [ExpectedOpeningBalance])),
	xpath(ExpectedReplyDOM, //LoanSummaryNode/InterestRateNode, element(_, _, [ExpectedInterestRate])),
	xpath(ExpectedReplyDOM, //LoanSummaryNode/MinYearlyRepaymentNode, element(_, _, [ExpectedMinYearlyRepayment])),
	xpath(ExpectedReplyDOM, //LoanSummaryNode/TotalRepaymentNode, element(_, _, [ExpectedTotalRepayment])),
	xpath(ExpectedReplyDOM, //LoanSummaryNode/RepaymentShortfallNode, element(_, _, [ExpectedRepaymentShortfall])),
	xpath(ExpectedReplyDOM, //LoanSummaryNode/TotalInterestNode, element(_, _, [ExpectedTotalInterest])),
	xpath(ExpectedReplyDOM, //LoanSummaryNode/TotalPrincipalNode, element(_, _, [ExpectedTotalPrincipal])),
	xpath(ExpectedReplyDOM, //LoanSummaryNode/ClosingBalanceNode, element(_, _, [ExpectedClosingBalance])),
			
	delete_file(TempLoanResponseFile),
	
	assertion(ActualOpeningBalance == ExpectedOpeningBalance),
	assertion(ActualInterestRate == ExpectedInterestRate),
	assertion(ActualMinYearlyRepayment == ExpectedMinYearlyRepayment),
	assertion(ActualTotalRepayment == ExpectedTotalRepayment),
	assertion(ActualRepaymentShortfall == ExpectedRepaymentShortfall),
	assertion(ActualTotalInterest == ExpectedTotalInterest),
	assertion(ActualTotalPrincipal == ExpectedTotalPrincipal),
	assertion(ActualClosingBalance == ExpectedClosingBalance). 

:- end_tests(process_xml_loan_request).

:- run_tests.
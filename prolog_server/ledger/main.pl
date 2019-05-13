%--------------------------------------------------------------------
% Load files --- needs to be turned into modules
%--------------------------------------------------------------------

:- debug.

:- ['./../../src/days.pl'].
:- ['./../../src/ledger.pl'].
:- ['./../../src/statements.pl'].
:- ['./../prolog_server.pl'].
:- ['./process_xml_request.pl'].

%:- run_server.
:- process_xml_document("ledger-request.xml").
:- halt.


bbb :- 
	balance_sheet_at(
	[
		exchange_rate(736875,'BHP','USD',2.0),
		exchange_rate(736875,'TLS','AUD',5.0)
	],
	[
		account('Assets','Accounts'),
		account('Equity','Accounts'),
		account('Liabilities','Accounts'),
		account('Earnings','Accounts'),
		account('RetainedEarnings','Accounts'),
		account('CurrentEarningsLosses','Accounts'),
		account('Revenue','Earnings'),
		account('Expenses','Earnings'),
		account('CurrentAssets','Assets'),
		account('CashAndCashEquivalents','CurrentAssets'),
		account('WellsFargo','CashAndCashEquivalents'),
		account('NationalAustraliaBank','CashAndCashEquivalents'),
		account('NoncurrentAssets','Assets'),
		account('FinancialInvestments','NoncurrentAssets'),
		account('NoncurrentLiabilities','Liabilities'),
		account('NoncurrentLoans','NoncurrentLiabilities'),
		account('CurrentLiabilities','Liabilities'),
		account('CurrentLoans','CurrentLiabilities'),
		account('ShareCapital','Equity'),
		account('InvestmentIncome','Revenue'),
		account('BankCharges','Expenses'),
		account('ForexLoss','Expenses'),
		account('CurrentEarningsLosses','Earnings'),
		account('RetainedEarnings','Earnings')
	],	
	[
		transaction(736542,"Shares",'NationalAustraliaBank',[coord('AUD',100.0,0.0)]),
		transaction(736542,"Shares",'NoncurrentLoans',[coord('AUD',0.0,100.0)]),
		transaction(736542,"Shares",'InvestmentIncome',[coord('AUD',0.0,0.0)]),
		transaction(736908,"Shares",'NationalAustraliaBank',[coord('AUD',0.0,50.0)]),
		transaction(736908,"Shares",'FinancialInvestments',[coord('TLS',10.0,0.0)]),
		transaction(736908,"Shares",'InvestmentIncome',[coord('AUD',50.0,0.0),coord('TLS',0.0,10.0)]),
		transaction(736511,"Unit_Investment",'WellsFargo',[coord('USD',200.0,0.0)]),
		transaction(736511,"Unit_Investment",'ShareCapital',[coord('AUD',0.0,260.1118)]),
		transaction(736511,"Unit_Investment",'InvestmentIncome',[coord('USD',0.0,200.0),coord('AUD',260.1118,0.0)]),
		transaction(736520,"Shares",'WellsFargo',[coord('USD',0.0,100.0)]),
		transaction(736520,"Shares",'FinancialInvestments',[coord('BHP',10.0,0.0)]),
		transaction(736520,"Shares",'InvestmentIncome',[coord('USD',100.0,0.0),coord('BHP',0.0,10.0)]),
		transaction(736873,"No Description",'WellsFargo',[coord('USD',0.0,10.0)]),
		transaction(736873,"No Description",'BankCharges',[coord('AUD',13.60971,0.0)]),
		transaction(736873,"No Description",'InvestmentIncome',[coord('USD',10.0,0.0),coord('AUD',0.0,13.60971)])
	],
	['AUD'],
	736875,
	735780,
	736875,
	_12910
).

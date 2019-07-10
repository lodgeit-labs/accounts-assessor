/* simple investment calculator
see doc/investment and dropbox Develop/videos/ledger
*/


:- module(
	process_xml_investment_request, 
	[process_xml_investment_request/2]).
:- use_module(library(xpath)).
:- use_module(library(record)).
:- use_module('../../lib/utils', [
	inner_xml/3, write_tag/2, fields/2, numeric_fields/2, 
	pretty_term_string/2 /*, magic_formula */, throw_string/1]).
:- use_module('../../lib/days', [format_date/2, parse_date/2, gregorian_date/2]).
:- use_module('../../lib/statements', [
		process_ledger/13,
		format_balance_sheet_entries/9]).
:- use_module('../../lib/accounts', [extract_account_hierarchy/2, account_ancestor_id/3]).
:- use_module('../../lib/ledger', [balance_sheet_at/8, trial_balance_between/8, profitandloss_between/8, balance_by_account/9]).
:- use_module('../../lib/pacioli',  [integer_to_coord/3]).


float_comparison_max_difference(0.00000001).

compare_floats(A, B) :-
	float_comparison_max_difference(Max),
	D is abs(A - B),
	D =< Max.


	
:- record investment(
	name, purchase_date, unit_cost, count, currency, 
	% purchase date rate of purchase currency to report currency
	purchase_date_rate, 
	report_date, 
	% report date cost in purchase currency
	report_date_cost,
	% report date rate of purchase currency to report currency
	report_date_rate).	
% for example: Google Shares	7/1/2015	10	100	USD	0.7	6/30/2016	20	0.65


process_realised(Dom, Result) :-
	Result = [S_Transactions, Exchange_Rates, Gains],
	Gains = [RC_Realised_Currency_Gain, RC_Realised_Market_Gain, 0, 0],
	
	/*
		PDPC = purchase date, purchase currency
		SDRC = sale date, report currency, etc
		SD = sale date
	*/

	fields(Dom, [
		'Name', Name, 
		'Currency', Currency_Extracted,
		'Purchase_Date', Purchase_Date_In,
		'Sale_Date', Sale_Date_In
	]),
	parse_date(Purchase_Date_In, Purchase_Date),
	parse_date(Sale_Date_In, Sale_Date),
	format_date(Sale_Date, Sale_Date_Out),
	format_date(Purchase_Date, Purchase_Date_Out),
	numeric_fields(Dom, [
		'Unit_Cost', PDPC_Unit_Cost,
		'Sale_Unit_Price', SDPC_Unit_Price,
		'Count', Count,
		'Purchase_Date_Rate', PD_Rate,
		'Sale_Date_Rate', SD_Rate
	]),
	writeln('<realised_investment>'),
	write_tag('Name', Name),
	write_tag('Count', Count),
	write_tag('Currency', Currency_Extracted),
	write_tag('Purchase_Date', Purchase_Date_Out),
	write_tag('Sale_Date', Sale_Date_Out),
	magic_formula(
		(
			PDPC_Total_Cost = Count * PDPC_Unit_Cost,
			PDRC_Total_Cost = PDPC_Total_Cost / PD_Rate,
			SDPC_Total_Value = Count * SDPC_Unit_Price,
			SDPC_Realised_Gain = SDPC_Total_Value - PDPC_Total_Cost,
			SDRC_Old_Rate_Total_Value = SDPC_Total_Value / PD_Rate,
			SDRC_New_Rate_Total_Value = SDPC_Total_Value / SD_Rate,		
			RC_Realised_Total_Gain = SDRC_New_Rate_Total_Value - PDRC_Total_Cost,
			RC_Realised_Market_Gain = SDRC_Old_Rate_Total_Value - PDRC_Total_Cost,
			RC_Realised_Currency_Gain = RC_Realised_Total_Gain - RC_Realised_Market_Gain
		)
	),
	/* silence singleton variable warning */ 
	nonvar(SDPC_Realised_Gain),
	writeln('</realised_investment>'),nl,nl,
	
	/*
	now for the cross check..
	*/
	gensym(Currency_Extracted, Currency_Unique),
	gensym(Name, Unit_Unique),
	
	Exchange_Rates = [
			exchange_rate(Purchase_Date, report_currency, Currency_Unique, PD_Rate),
			exchange_rate(Sale_Date, report_currency, Currency_Unique, SD_Rate),
			exchange_rate(Purchase_Date, Unit_Unique, Currency_Unique, PDPC_Unit_Cost),
			exchange_rate(Sale_Date, Unit_Unique, Currency_Unique, SDPC_Unit_Price)
	],
	extract_account_hierarchy([], Accounts0),
	S_Transactions = [
		s_transaction(
			Purchase_Date, 
			'Invest_In', 
			[coord(Currency_Unique, 0, PDPC_Total_Cost)], 
			'Bank', 
			vector([coord(Unit_Unique, Count, 0)])
		),
		s_transaction(
			Sale_Date, 
			'Dispose_Of', 
			[coord(Currency_Unique, SDPC_Total_Value, 0)], 
			'Bank', 
			vector([coord(Unit_Unique, 0, Count)])
		)
	], 
	process_ledger(
		[],
		S_Transactions,	
		Purchase_Date, 
		Sale_Date, 
		Exchange_Rates,
		[ transaction_type('Invest_In',
		   'Financial_Investments',
		   'Investment_Income',
		   'Shares'),
		transaction_type('Dispose_Of',
		   'Financial_Investments',
		   'Investment_Income',
		   'Shares')],
		[report_currency], 
		[], 
		[], 
		_, 
		Accounts0, 
		Accounts1, 
		Transactions
	),
   	Info = (Exchange_Rates, Accounts1, Transactions, Sale_Date, report_currency),
   
    account_assertion(Info, 'Realised_Gains_Excluding_Forex', -RC_Realised_Market_Gain),
	account_assertion(Info, 'Realised_Gains_Currency_Movement', -RC_Realised_Currency_Gain),
	account_assertion(Info, 'Realised_Gain', -RC_Realised_Total_Gain),
	
	profitandloss_between(Exchange_Rates, Accounts1, Transactions, [report_currency], Sale_Date, Purchase_Date, Sale_Date, ProftAndLoss),
	format_balance_sheet_entries(Accounts1, 0, [report_currency], Sale_Date, ProftAndLoss, [], _, [], ProftAndLoss_Lines),
	writeln('<!--'),
	writeln(ProftAndLoss_Lines),
	writeln('-->'),
	balance_sheet_at(Exchange_Rates, Accounts1, Transactions, [report_currency], Sale_Date, Purchase_Date, Sale_Date, Balance_Sheet),
	format_balance_sheet_entries(Accounts1, 0, [report_currency], Sale_Date, Balance_Sheet, [], _, [], Balance_Sheet_Lines),
	writeln('<!--'),
	writeln(Balance_Sheet_Lines),
	writeln('-->'),

	
	true.



process_unrealised(Dom, Global_Report_Date, Result) :-
	Result = [S_Transactions, Exchange_Rates, Gains],
	Gains = [0,0,RDRC_Unrealised_Currency_Gain, RDRC_Unrealised_Market_Gain],
	/*
		PDPC = purchase date, purchase currency
		RDRC = report date, report currency, etc..
	*/

	fields(Dom, [
		'Name', Name, 
		'Currency', Currency_In,
		'Purchase_Date', Purchase_Date_In,
		'Report_Date', (Report_Date_In, _)
	       ]),
	(
		Global_Report_Date = Report_Date_In
	->true
	; throw_string('global report date does not match investment report date') 
	),
	(
		var(Report_Date_In)
	->	throw_string('report date missing')
	;	true),
	
	parse_date(Purchase_Date_In, Purchase_Date),
	parse_date(Report_Date_In, Report_Date),
	format_date(Report_Date, Report_Date_Out),
	format_date(Purchase_Date, Purchase_Date_Out),
	numeric_fields(Dom, [
		'Unit_Cost', PDPC_Unit_Cost,
		'Unit_Value', RDPC_Unit_Value,
		'Count', Count,
		'Purchase_Date_Rate', PD_Rate,
		'Report_Date_Rate', RD_Rate
	]),
	writeln('<unrealised_investment>'),
	write_tag('Name', Name),
	write_tag('Count', Count),
	write_tag('Currency', Currency_In),
	write_tag('Purchase_Date', Purchase_Date_Out),
	write_tag('Report_Date', Report_Date_Out),
	magic_formula(
		(
		
			PDPC_Total_Cost = Count * PDPC_Unit_Cost,			
			PDRC_Total_Cost = PDPC_Total_Cost / PD_Rate,
			RDPC_Total_Value = Count * RDPC_Unit_Value,
			RDPC_Unrealised_Gain = RDPC_Total_Value - PDPC_Total_Cost,
			RDRC_Old_Rate_Total_Value = RDPC_Total_Value / PD_Rate,
			RDRC_New_Rate_Total_Value = RDPC_Total_Value / RD_Rate,
			RDRC_Unrealised_Total_Gain = RDRC_New_Rate_Total_Value - PDRC_Total_Cost,
			RDRC_Unrealised_Market_Gain = RDRC_Old_Rate_Total_Value - PDRC_Total_Cost,
			RDRC_Unrealised_Currency_Gain = RDRC_Unrealised_Total_Gain - RDRC_Unrealised_Market_Gain
		)
	),
	/* silence singleton variable warning */
	nonvar(RDPC_Unrealised_Gain),
	writeln('</unrealised_investment>'),nl,nl,
	
	/*
	now for the cross check..
	*/
	gensym(Currency_In, Currency_Unique),
	gensym(Name, Unit_Unique),
	Exchange_Rates = [
			exchange_rate(Purchase_Date, report_currency, Currency_Unique, PD_Rate),
			exchange_rate(Report_Date, report_currency, Currency_Unique, RD_Rate),
			exchange_rate(Purchase_Date, Unit_Unique, Currency_Unique, PDPC_Unit_Cost),
			exchange_rate(Report_Date, Unit_Unique, Currency_Unique, RDPC_Unit_Value)
	],
	S_Transactions = [
		s_transaction(
			Purchase_Date, 
			'Invest_In', 
			[coord(Currency_Unique, 0, PDPC_Total_Cost)], 
			'Bank', 
			vector([coord(Unit_Unique, Count, 0)])
		)
	],	

	extract_account_hierarchy([], Accounts0),
	process_ledger(
		[],
		S_Transactions,
		Purchase_Date, 
		Report_Date, 
		Exchange_Rates,
		[ transaction_type('Invest_In',
		   'Financial_Investments',
		   'Investment_Income',
		   'Shares')
		],
		[report_currency], 
		[], 
		[], 
		_, 
		Accounts0, 
		Accounts1, 
		Transactions
	),
   	Info = (Exchange_Rates, Accounts1, Transactions, Report_Date, report_currency),
   
	account_assertion(Info, 'Unrealised_Gains_Excluding_Forex', -RDRC_Unrealised_Market_Gain),
	account_assertion(Info, 'Unrealised_Gains_Currency_Movement', -RDRC_Unrealised_Currency_Gain),
	account_assertion(Info, 'Unrealised_Gain', -RDRC_Unrealised_Total_Gain),
	
	profitandloss_between(Exchange_Rates, Accounts1, Transactions, [report_currency], Report_Date, Purchase_Date, Report_Date, ProftAndLoss),
	format_balance_sheet_entries(Accounts1, 0, [report_currency], Report_Date, ProftAndLoss, [], _, [], ProftAndLoss_Lines),
	writeln('<!--'),
	writeln(ProftAndLoss_Lines),
	writeln('-->'),
	balance_sheet_at(Exchange_Rates, Accounts1, Transactions, [report_currency], Report_Date, Purchase_Date, Report_Date, Balance_Sheet),
	format_balance_sheet_entries(Accounts1, 0, [report_currency], Report_Date, Balance_Sheet, [], _, [], Balance_Sheet_Lines),
	writeln('<!--'),
	writeln(Balance_Sheet_Lines),
	writeln('-->'),

	
	true.
		

	
	
account_assertion(Info, Account, Expected_Exp) :-
	Info = (_,_,_,_,Currency),
	account_vector(Info, Account, Vector),
	Vector = [Coord],
	integer_to_coord(Currency, Balance, Coord),
	Expected is Expected_Exp,
	assertion(compare_floats(Balance, Expected)).

account_vector(Info, Account, Vector) :-
	Info = (Exchange_Rates, Accounts, Transactions, Report_Date, Currency), 
    balance_by_account(Exchange_Rates, Accounts, Transactions, [Currency], Report_Date, Account, Report_Date, Vector, _).
    
    
		

process_xml_investment_request(_, DOM) :-
	xpath(DOM, //reports/investments, _),
	writeln('<?xml version="1.0"?>'),
	writeln('<response>'),
	xpath(DOM, //reports, Reports),
	% get global report date
	fields(Reports, [report_date, (Report_Date, _)]),
	(
		nonvar(Report_Date)
	->	write_tag('Report_Date', Report_Date)
	;true
	),
	findall(
		Result,
		process_investments(DOM, Report_Date, Result),
		Results
	),
	(
		nonvar(Report_Date)
	->	cross_check_totals(Results, Report_Date)
	;	true
	),
	writeln('<!--'),
	writeln(Results),
	writeln('-->'),
	writeln('</response>'),
	nl, nl.

process_investments(DOM, Report_Date, Result) :-
	% for each unrealised investment, we will unify investment report date against global report date
	% if different, fail processing (throw error)
	xpath(DOM, //reports/investments/(*), Investment),
	(
		process(Investment, Report_Date, Result)
	->	true
	;
	(
		term_string(Investment, Investment_Str),
		throw_string(['failed processing:',Investment_Str])
	)
	).
	

process(Investment, _, Result) :-
	xpath(Investment, //realised_investment, _),
	process_realised(Investment, Result).

process(Investment, Report_Date, Result) :-
	xpath(Investment, //unrealised_investment, _),
	process_unrealised(Investment, Report_Date, Result).

crosscheck_total(Results, Report_Date) :-
	extract_account_hierarchy([], Accounts0),
	maplist(nth(0), Results, S_Transaction_Lists),
	maplist(nth(1), Results, Exchange_Rates_Lists),
	maplist(nth(2), Results, Gains_List),
	flatten(S_Transaction_Lists,S_Transactions),
	flatten(Exchange_Rates_Lists,Exchange_Rates),
	
	maplist(nth(0), Gains_List, Realised_Currency_Gain_List),
	maplist(nth(1), Gains_List, Realised_Market_Gain_List),
	maplist(nth(2), Gains_List, Unrealised_Currency_Gain_List),
	maplist(nth(3), Gains_List, Unrealised_Market_Gain_List),
	
	sum_list(Realised_Currency_Gain_List, Realised_Currency_Gain_Total),
	sum_list(Realised_Market_Gain_List, Realised_Market_Gain_Total),
	sum_list(Unrealised_Currency_Gain_List, Unrealised_Currency_Gain_Total),
	sum_list(Unrealised_Market_Gain_List, Unrealised_Market_Gain_Total),

	process_ledger(
		[],
		S_Transactions,
		infinity, 
		Report_Date, 
		Exchange_Rates,
		[ transaction_type('Invest_In',
		   'Financial_Investments',
		   'Investment_Income',
		   'Shares'),
		  transaction_type('Dispose_Of',
		   'Financial_Investments',
		   'Investment_Income',
		   'Shares')
		],
		[report_currency], 
		[], 
		[], 
		_, 
		Accounts0, 
		Accounts1, 
		Transactions
	),
   	Info = (Exchange_Rates, Accounts1, Transactions, Report_Date, report_currency),

	account_assertion(Info, 'Realised_Gains_Excluding_Forex', -Realised_Market_Gain_Total),
	account_assertion(Info, 'Realised_Gains_Currency_Movement', -Realised_Currency_Gain_Total),
	account_assertion(Info, 'Unrealised_Gains_Excluding_Forex', -Unrealised_Market_Gain_Total),
	account_assertion(Info, 'Unrealised_Gains_Currency_Movement', -Unrealised_Currency_Gain_Total),
	
	profitandloss_between(Exchange_Rates, Accounts1, Transactions, [report_currency], Report_Date, infinity, Report_Date, ProftAndLoss),
	format_balance_sheet_entries(Accounts1, 0, [report_currency], Report_Date, ProftAndLoss, [], _, [], ProftAndLoss_Lines),
	writeln('<!--'),
	writeln(ProftAndLoss_Lines),
	writeln('-->'),
	balance_sheet_at(Exchange_Rates, Accounts1, Transactions, [report_currency], Report_Date, infinity, Report_Date, Balance_Sheet),
	format_balance_sheet_entries(Accounts1, 0, [report_currency], Report_Date, Balance_Sheet, [], _, [], Balance_Sheet_Lines),
	writeln('<!--'),
	writeln(Balance_Sheet_Lines),
	writeln('-->').

	

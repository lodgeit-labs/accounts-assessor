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
	pretty_term_string/2 /*, magic_formula */]).
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


process_realized(Dom, _Result) :-
	/*
		PDPC = purchase date, purchase currency
		SDRC = sale date, report currency, etc
		SD = sale date
	*/

	fields(Dom, [
		'Name', Name, 
		'Currency', Currency,
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
	writeln('<realized_investment>'),
	write_tag('Name', Name),
	write_tag('Count', Count),
	write_tag('Currency', Currency),
	write_tag('Purchase_Date', Purchase_Date_Out),
	write_tag('Sale_Date', Sale_Date_Out),
	magic_formula(
		(
			PDPC_Total_Cost = Count * PDPC_Unit_Cost,
			PDRC_Total_Cost = PDPC_Total_Cost / PD_Rate,
			SDPC_Total_Value = Count * SDPC_Unit_Price,
			SDPC_Realized_Gain = SDPC_Total_Value - PDPC_Total_Cost,
			SDRC_Old_Rate_Total_Value = SDPC_Total_Value / PD_Rate,
			SDRC_New_Rate_Total_Value = SDPC_Total_Value / SD_Rate,		
			RC_Realised_Total_Gain = SDRC_New_Rate_Total_Value - PDRC_Total_Cost,
			RC_Realised_Market_Gain = SDRC_Old_Rate_Total_Value - PDRC_Total_Cost,
			RC_Realised_Currency_Gain = RC_Realised_Total_Gain - RC_Realised_Market_Gain
		)
	),
	/* silence singleton variable warning */ 
	nonvar(SDPC_Realized_Gain),
	writeln('</investment>'),nl,nl,
	
	/*
	now for the cross check..
	*/	
	Exchange_Rates = [
			exchange_rate(Purchase_Date, report_currency, Currency, PD_Rate),
			exchange_rate(Sale_Date, report_currency, Currency, SD_Rate),
			exchange_rate(Purchase_Date, Name, Currency, PDPC_Unit_Cost),
			exchange_rate(Sale_Date, Name, Currency, SDPC_Unit_Price)
	],
	extract_account_hierarchy([], Accounts0),
	process_ledger(
		[],
		[
		s_transaction(
			Purchase_Date, 
			'Invest_In', 
			[coord(Currency, 0, PDPC_Total_Cost)], 
			'Bank', 
			vector([coord(Name, Count, 0)])),
		s_transaction(
			Sale_Date, 
			'Dispose_Of', 
			[coord(Currency, SDPC_Total_Value, 0)], 
			'Bank', 
			vector([coord(Name, 0, Count)]))
		],	
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
   
    account_assertion(Info, 'Realized_Gains_Excluding_Forex', -RC_Realised_Market_Gain),
	account_assertion(Info, 'Realized_Gains_Currency_Movement', -RC_Realised_Currency_Gain),
	account_assertion(Info, 'Realized_Gain', -RC_Realised_Total_Gain),
	
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
		



%	Gains = (RDRC_Realised_Currency_Gain, RDRC_Realised_market_Gain



process_unrealized(Dom, Result) :-
	Result = (_S_Transactions, Exchange_Rates, Gains),
	Gains = (0,0,RDRC_Unrealised_Currency_Gain, RDRC_Unrealised_Market_Gain),
	/*
		PDPC = purchase date, purchase currency
		RDRC = report date, report currency, etc..
	*/

	fields(Dom, [
		'Name', Name, 
		'Currency', Currency,
		'Purchase_Date', Purchase_Date_In,
		'Report_Date', Report_Date_In
	]),
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
	writeln('<investment>'),
	write_tag('Name', Name),
	write_tag('Count', Count),
	write_tag('Currency', Currency),
	write_tag('Purchase_Date', Purchase_Date_Out),
	write_tag('Report_Date', Report_Date_Out),
	magic_formula(
		(
		
			PDPC_Total_Cost = Count * PDPC_Unit_Cost,			
			PDRC_Total_Cost = PDPC_Total_Cost / PD_Rate,
			RDPC_Total_Value = Count * RDPC_Unit_Value,
			RDPC_Unrealized_Gain = RDPC_Total_Value - PDPC_Total_Cost,
			RDRC_Old_Rate_Total_Value = RDPC_Total_Value / PD_Rate,
			RDRC_New_Rate_Total_Value = RDPC_Total_Value / RD_Rate,
			RDRC_Unrealised_Total_Gain = RDRC_New_Rate_Total_Value - PDRC_Total_Cost,
			RDRC_Unrealised_Market_Gain = RDRC_Old_Rate_Total_Value - PDRC_Total_Cost,
			RDRC_Unrealised_Currency_Gain = RDRC_Unrealised_Total_Gain - RDRC_Unrealised_Market_Gain
		)
	),
	/* silence singleton variable warning */
	nonvar(RDPC_Unrealized_Gain),
	writeln('</investment>'),nl,nl,
	
	/*
	now for the cross check..
	*/	
	Exchange_Rates = [
			exchange_rate(Purchase_Date, report_currency, Currency, PD_Rate),
			exchange_rate(Report_Date, report_currency, Currency, RD_Rate),
			exchange_rate(Purchase_Date, Name, Currency, PDPC_Unit_Cost),
			exchange_rate(Report_Date, Name, Currency, RDPC_Unit_Value)
	],
	extract_account_hierarchy([], Accounts0),
	process_ledger(
		[],
		[
		s_transaction(
			Purchase_Date, 
			'Invest_In', 
			[coord(Currency, 0, PDPC_Total_Cost)], 
			'Bank', 
			vector([coord(Name, Count, 0)]))
		],	
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
   
	account_assertion(Info, 'Unrealized_Gains_Excluding_Forex', -RDRC_Unrealised_Market_Gain),
	account_assertion(Info, 'Unrealized_Gains_Currency_Movement', -RDRC_Unrealised_Currency_Gain),
	account_assertion(Info, 'Unrealized_Gain', -RDRC_Unrealised_Total_Gain),
	
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
	findall(
		Result,
		process_investments(DOM, Result),
		Results
	),
	writeln('<!--'),
	writeln(Results),
	writeln('-->'),
	writeln('</response>'),
	nl, nl.

process_investments(DOM, Result) :-
	xpath(DOM, //reports/investments/(*), Investment),
	process(Investment, Result).

process(Investment, Result) :-
	xpath(Investment, //realized_investment, _),
	process_realized(Investment, Result).

process(Investment, Result) :-
	xpath(Investment, //unrealized_investment, _),
	process_unrealized(Investment, Result).
	
							    
	
/*
process(Investment, Result) :-
	result = result(
		% on purchase date in purchase currency
		Total_Cost, 
		% on purchase date
		Report_Currency_Cost, 
		% at report date in purchase currency
		Total_Market_Value,
		Unrealized_Gain,
		% at report date
		Report_Currency_Market_Value,
		% at report date in report currency
		Total_Gain, Market_Gain, Currency_Gain),
*/	

/*Investment = investment(
		Name, Purchase_Currency, Purchase_Date, Count, 
		on_purchase_date{unit_cost: Unit_Cost, rate:Rate}, 
		on_report_date{unit_value:Unit_Value, rate:Rate}),
	Investment = investment(
		'Google', 'USD', date(2015,7,1), 10, 
		on_purchase_date{unit_cost: 10, rate:0.7}, 
		on_report_date{unit_value:20, rate:0.65}),
*/


/*
Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.
*/



/*
	Investment = investment(
		Name, 
		Purchase_Date, 
		Count,
		Currency, 
		Report_Date,
		PDPC_Unit_Cost, 
		RDPC_Unit_Value,
		PD_Rate,
		RD_Rate
	).

	
:- initialization(test0).

test0 :-
	process(investment(
		'Google', 
		date(2015,7,1), 
		100, 
		'USD', 
		date(2016,6,30), 
		10, 
		20,
		0.7,
		0.65)
	))).
	
	
process(Investment) :-
	Investment = investment(
		Name, 
		Purchase_Date, 
		Count,
		Currency, 
		Report_Date,
		PDPC_Unit_Cost, 
		RDPC_Unit_Value,
		PD_Rate,
		RD_Rate
	),
*/


	% realized_gain_investment_currency(investment) = 
	% rate(investment.item,investment.currency,investment.sale_date)*investment.sale_count -
	% rate(investment.item,investment.currency,investment.purchase_date)*investment.sale_count


/*
rate_of (item) at (report_date) in (report_currency) without_movement_of (purchase_currency) against (report_currency) since (purchase_date)) = 
	rate0 = rate(item, report_currency, report_date) /
	rate1 = rate(purchase_currency, report_currency, purchase_date) *
	rate2 = rate(purchase_currency, report_currency, report_date)
	
	(rate0 / rate2) * rate1

goog 10 usd now = 20 aud
old 1 usd = 5 aud
new 1 usd = 2 aud 
goog at old rate = 50 aud
goog at new rate = 20 aud
20/2*5 = 50 aud


*/

/*
value_without_currency_movement(investment) = 
	rate of (investment.item) 
		at (investment.sale_date) 
		in (report.currency) 
		without movement of (investment.purchase_currency) 
		against (report.currency) 
		since (investment.purchase_date)


*/

/*
realized_gain_no_forex_report_currency(investment) =
	value_without_currency_movement(investment) - 
	rate(investment.item,report.currency,investment.purchase_date)*investment.sale_count
*/

/*
realized_gain_forex_in_report_currency(investment) = 
	rate(investment.item,report.currency,investment.sale_date) * investment.sale_count - 
	value_without_currency_movement(investment)


*/

/*
total_realized_gain_report_currecy(investment) =
	rate(investment.item, report.currency, investment.sale_date) * investment.sale_count -
	rate(investment.item, report.currency, investment.purchase_date) * investment.sale_count

 = 	realized_gain_no_forex_report_currency(investment) + 
	realized_gain_forex_in_report_currency(investment)

*/

/*

*/

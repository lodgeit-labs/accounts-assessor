/* simple investment calculator
see doc/investment and dropbox Develop/videos/ledger
*/

:- module(process_xml_investment_request, 
		[process_xml_investment_request/2]).
		
		
:- use_module(library(xpath)).
:- use_module(library(record)).
:- use_module(library(lists)).
:- use_module('../../lib/utils', [
		inner_xml/3, 
		write_tag/2, 
		fields/2, 
		numeric_fields/2, 
		floats_close_enough/2,
		pretty_term_string/2,
		/* magic_formula, */
		throw_string/1]).
:- use_module('../../lib/days', [
		format_date/2, 
		parse_date/2, 
		gregorian_date/2]).
:- use_module('../../lib/ledger', [
		process_ledger/13]).
:- use_module('../../lib/ledger_report', [
		format_report_entries/10,
		balance_sheet_at/8, 
		trial_balance_between/8, 
		profitandloss_between/8, 
		balance_by_account/9]).
:- use_module('../../lib/accounts', [
		extract_account_hierarchy/2, 
		account_by_role/3]).
:- use_module('../../lib/pacioli',  [
		number_coord/3,
		vec_add/3]).


	
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


process_realized(Dom, Global_Report_Date_Atom, Result) :-
	Result = [S_Transactions, Exchange_Rates, Gains, PDRC_Costs, PDPC_Costs, SDRC_New_Rate_Total_Value],
	Gains = [RC_Realized_Currency_Gain, RC_Realized_Market_Gain, 0, 0],
	PDRC_Costs = [PDRC_Total_Cost,0],
	PDPC_Costs = [PDPC_Total_Cost,0],

	/*
		PDPC = purchase date, purchase currency
		SDRC = sale date, report currency, etc
		SD = sale date
	*/

	fields(Dom, [
		'Name', Name, 
		'Currency', Currency_Extracted,
		'Purchase_Date', Purchase_Date_In,
		'Sale_Date', (Sale_Date_In, _)
	]),
	(
		Global_Report_Date_Atom = Sale_Date_In
	->true
	; throw_string('global report date does not match investment sale date') 
	),
	(
		var(Sale_Date_In)
	->	throw_string('sale date missing')
	;	true),
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
	write_tag('Currency', Currency_Extracted),
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
			RC_Realized_Total_Gain = SDRC_New_Rate_Total_Value - PDRC_Total_Cost,
			RC_Realized_Market_Gain = SDRC_Old_Rate_Total_Value - PDRC_Total_Cost,
			RC_Realized_Currency_Gain = RC_Realized_Total_Gain - RC_Realized_Market_Gain
		)
	),
	/* silence singleton variable warning */ 
	nonvar(SDPC_Realized_Gain),
	writeln('</realized_investment>'),nl,nl,
	
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
		Accounts0, 
		Accounts1, 
		Transactions,
		_
	),
   	Info = (Exchange_Rates, Accounts1, Transactions, Sale_Date, report_currency),
	account_by_role(Accounts1, 'Investment_Income'/realized, Gain_Account),
	account_by_role(Accounts1, Gain_Account/without_currency_movement, Gains_Excluding_Forex_Account),
	account_by_role(Accounts1, Gain_Account/only_currency_movement, Gains_Currency_Movement_Account), 
    account_assertion(Info, Gains_Excluding_Forex_Account, -RC_Realized_Market_Gain),
	account_assertion(Info, Gains_Currency_Movement_Account, -RC_Realized_Currency_Gain),
	account_assertion(Info, Gain_Account, -RC_Realized_Total_Gain),
	
	profitandloss_between(Exchange_Rates, Accounts1, Transactions, [report_currency], Sale_Date, Purchase_Date, Sale_Date, ProftAndLoss),
	format_report_entries(xbrl, Accounts1, 0, [report_currency], Sale_Date, ProftAndLoss, [], _, [], ProftAndLoss_Lines),
	writeln('<!--'),
	writeln(ProftAndLoss_Lines),
	writeln('-->'),
	balance_sheet_at(Exchange_Rates, Accounts1, Transactions, [report_currency], Sale_Date, Purchase_Date, Sale_Date, Balance_Sheet),
	format_report_entries(xbrl, Accounts1, 0, [report_currency], Sale_Date, Balance_Sheet, [], _, [], Balance_Sheet_Lines),
	writeln('<!--'),
	writeln(Balance_Sheet_Lines),
	writeln('-->'),
	true.

process_unrealized(Dom, Global_Report_Date, Result) :-
	Result = [S_Transactions, Exchange_Rates, Gains, PDRC_Costs, PDPC_Costs, 0],
	Gains = [0,0,RDRC_Unrealized_Currency_Gain, RDRC_Unrealized_Market_Gain],
	PDRC_Costs = [0,PDRC_Total_Cost],
	PDPC_Costs = [0,PDPC_Total_Cost],
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
	writeln('<unrealized_investment>'),
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
			RDPC_Unrealized_Gain = RDPC_Total_Value - PDPC_Total_Cost,
			RDRC_Old_Rate_Total_Value = RDPC_Total_Value / PD_Rate,
			RDRC_New_Rate_Total_Value = RDPC_Total_Value / RD_Rate,
			RDRC_Unrealized_Total_Gain = RDRC_New_Rate_Total_Value - PDRC_Total_Cost,
			RDRC_Unrealized_Market_Gain = RDRC_Old_Rate_Total_Value - PDRC_Total_Cost,
			RDRC_Unrealized_Currency_Gain = RDRC_Unrealized_Total_Gain - RDRC_Unrealized_Market_Gain
		)
	),
	/* silence singleton variable warning */
	nonvar(RDPC_Unrealized_Gain),
	writeln('</unrealized_investment>'),nl,nl,
	
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
		Accounts0, 
		Accounts1, 
		Transactions,
		_
	),
	
	profitandloss_between(Exchange_Rates, Accounts1, Transactions, [report_currency], Report_Date, Purchase_Date, Report_Date, ProftAndLoss),
	format_report_entries(xbrl, Accounts1, 0, [report_currency], Report_Date, ProftAndLoss, [], _, [], ProftAndLoss_Lines),
	writeln('<!--'),
	writeln(ProftAndLoss_Lines),
	writeln('-->'),
	balance_sheet_at(Exchange_Rates, Accounts1, Transactions, [report_currency], Report_Date, Purchase_Date, Report_Date, Balance_Sheet),
	format_report_entries(xbrl, Accounts1, 0, [report_currency], Report_Date, Balance_Sheet, [], _, [], Balance_Sheet_Lines),
	writeln('<!--'),
	writeln(Balance_Sheet_Lines),
	writeln('-->'),

   	Info = (Exchange_Rates, Accounts1, Transactions, Report_Date, report_currency),
	account_by_role(Accounts1, 'Investment_Income'/unrealized, Unrealized_Gain_Account),
	account_by_role(Accounts1, Unrealized_Gain_Account/without_currency_movement, Unrealized_Gains_Excluding_Forex_Account),
	account_by_role(Accounts1, Unrealized_Gain_Account/only_currency_movement, Unrealized_Gains_Currency_Movement_Account),
   	account_assertion(Info, Unrealized_Gains_Excluding_Forex_Account, -RDRC_Unrealized_Market_Gain),
	account_assertion(Info, Unrealized_Gains_Currency_Movement_Account, -RDRC_Unrealized_Currency_Gain),
	account_assertion(Info, Unrealized_Gain_Account, -RDRC_Unrealized_Total_Gain),

	true.

/*
  Check that balance in `Account` matches `Expected_Exp` within tolerance
  for float comparisons.
*/	
floats_close_enough2(_Description,actual(A),expected(B)) :-
	floats_close_enough(A,B).

account_assertion(Info, Account, Expected_Exp) :-
	Info = (_,_,_,_,Currency),
	account_vector(Info, Account, Vector),
	(
		(
			Vector = [Coord],
			number_coord(Currency, Balance, Coord),
			!
		)
	;	(	
			Vector = [],
			Balance = 0,
			!
		)
	;	(
			throw(('unexpected balance:', Vector))
		)
	),
	Expected is Expected_Exp,
	assertion(floats_close_enough2(Account, actual(Balance), expected(Expected))).

/*
  Retrieve Debit/Credit vector form of balance for `Account`, return as `Vector`.
*/
account_vector(Info, Account, Vector) :-
	Info = (Exchange_Rates, Accounts, Transactions, Report_Date, Currency), 
    balance_by_account(Exchange_Rates, Accounts, Transactions, [Currency], Report_Date, Account, Report_Date, Vector, _).

process_xml_investment_request(_, DOM) :-
	xpath(DOM, //reports/investmentRequest/investments, _),
	writeln('<?xml version="1.0"?>'),
	writeln('<response>'),
	xpath(DOM, //reports/investmentRequest, InvestmentRequest),
	% get global report date
	fields(InvestmentRequest, [report_date, (Report_Date, _)]),
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
	get_totals(Results, Processed_Results),
	(
		nonvar(Report_Date)
	->	
		(
			parse_date(Report_Date, Report_Date_Parsed),
			crosscheck_totals(Processed_Results, Report_Date_Parsed)
		)
	;
		true
	),
	Processed_Results = (_, _, Totals),
	print_totals(Totals),
	writeln('</response>'),
	nl, nl.

process_investments(DOM, Report_Date, Result) :-
	% for each unrealized investment, we will unify investment report date against global report date
	% if different, fail processing (throw error)
	xpath(DOM, //reports/investmentRequest/investments/(*), Investment),
	(
		process(Investment, Report_Date, Result)
	->	true
	;
	(
		term_string(Investment, Investment_Str),
		throw_string(['failed processing:',Investment_Str])
	)
	).
	
process(Investment, Report_Date, Result) :-
	xpath(Investment, //realized_investment, _),
	process_realized(Investment, Report_Date, Result).

process(Investment, Report_Date, Result) :-
	xpath(Investment, //unrealized_investment, _),
	process_unrealized(Investment, Report_Date, Result).

get_totals(Results_In, Results_Out) :-
	Results_Out = (S_Transactions, Exchange_Rates, Totals),
	Totals = (
		Realized_Currency_Gain_Total, 
		Realized_Market_Gain_Total,
		Realized_Gain_Total,
		Unrealized_Currency_Gain_Total,
		Unrealized_Market_Gain_Total,
		Unrealized_Gain_Total,
		Gain_Total,
		PDRC_Cost_Total,
		PDPC_Cost_Total,
		SDRC_Value_Total,
		Unrealized_PDRC_Cost_Total
	),

	

	maplist(nth0(0), Results_In, S_Transaction_Lists),
	maplist(nth0(1), Results_In, Exchange_Rates_Lists),
	maplist(nth0(2), Results_In, Gains_List),
	maplist(nth0(3), Results_In, PDRC_Cost_List),
	maplist(nth0(4), Results_In, PDPC_Cost_List),
	maplist(nth0(5), Results_In, SDRC_Value_List),
	flatten(S_Transaction_Lists,S_Transactions),
	flatten(Exchange_Rates_Lists,Exchange_Rates),
	
	% Gains Totals
	maplist(nth0(0), Gains_List, Realized_Currency_Gain_List),
	maplist(nth0(1), Gains_List, Realized_Market_Gain_List),
	maplist(nth0(2), Gains_List, Unrealized_Currency_Gain_List),
	maplist(nth0(3), Gains_List, Unrealized_Market_Gain_List),
	
	sum_list(Realized_Currency_Gain_List, Realized_Currency_Gain_Total),
	sum_list(Realized_Market_Gain_List, Realized_Market_Gain_Total),
	sum_list(Unrealized_Currency_Gain_List, Unrealized_Currency_Gain_Total),
	sum_list(Unrealized_Market_Gain_List, Unrealized_Market_Gain_Total),


	Realized_Gain_Total is Realized_Currency_Gain_Total + Realized_Market_Gain_Total,
	Unrealized_Gain_Total is Unrealized_Currency_Gain_Total + Unrealized_Market_Gain_Total,
	Gain_Total is Realized_Gain_Total + Unrealized_Gain_Total,


	% PDRC Cost Totals
	maplist(nth0(0), PDRC_Cost_List, Realized_PDRC_Cost_List),
	maplist(nth0(1), PDRC_Cost_List, Unrealized_PDRC_Cost_List),

	sum_list(Realized_PDRC_Cost_List, Realized_PDRC_Cost_Total),
	sum_list(Unrealized_PDRC_Cost_List, Unrealized_PDRC_Cost_Total),

	PDRC_Cost_Total is Realized_PDRC_Cost_Total + Unrealized_PDRC_Cost_Total,

	% PDPC Cost Totals
	maplist(nth0(0), PDPC_Cost_List, Realized_PDPC_Cost_List),
	maplist(nth0(1), PDPC_Cost_List, Unrealized_PDPC_Cost_List),

	sum_list(Realized_PDPC_Cost_List, Realized_PDPC_Cost_Total),
	sum_list(Unrealized_PDPC_Cost_List, Unrealized_PDPC_Cost_Total),

	PDPC_Cost_Total is Realized_PDPC_Cost_Total + Unrealized_PDPC_Cost_Total,


	% SDPC Value Totals
	sum_list(SDRC_Value_List, SDRC_Value_Total).

crosscheck_totals(Results, Report_Date) :-
	writeln('<!-- Totals cross-check: -->'),

	Results = (S_Transactions, Exchange_Rates, Totals),
	Totals = (
		Realized_Currency_Gain_Total,
		Realized_Market_Gain_Total,
		_Realized_Gain_Total,
		Unrealized_Currency_Gain_Total,
		Unrealized_Market_Gain_Total,
		_Unrealized_Gain_Total,
		Gain_Total,
		PDRC_Cost_Total,
		_PDPC_Cost_Total,
		SDRC_Value_Total,
		_Unrealized_PDRC_Cost_Total
	),
	extract_account_hierarchy([], Accounts0),

	process_ledger(
		[],
		S_Transactions,
		date(2000,1,1), 
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
		Accounts0, 
		Accounts1, 
		Transactions,
		_
	),
   	Info = (Exchange_Rates, Accounts1, Transactions, Report_Date, report_currency),
	/*
		PL cross-check
	*/
	writeln("PL cross-check"),
	account_by_role(Accounts1, 'Investment_Income'/unrealized, Unrealized_Gain_Account),
	account_by_role(Accounts1, 'Investment_Income'/realized, Realized_Gain_Account),
	account_by_role(Accounts1, Unrealized_Gain_Account/without_currency_movement, Unrealized_Gains_Excluding_Forex_Account),
	account_by_role(Accounts1, Unrealized_Gain_Account/only_currency_movement, Unrealized_Gains_Currency_Movement_Account),
	account_by_role(Accounts1, Realized_Gain_Account/without_currency_movement, Realized_Gains_Excluding_Forex_Account),
	account_by_role(Accounts1, Realized_Gain_Account/only_currency_movement, Realized_Gains_Currency_Movement_Account),
	account_assertion(Info, Realized_Gains_Excluding_Forex_Account, -Realized_Market_Gain_Total),
	account_assertion(Info, Realized_Gains_Currency_Movement_Account, -Realized_Currency_Gain_Total),
	account_assertion(Info, Unrealized_Gains_Excluding_Forex_Account, -Unrealized_Market_Gain_Total),
	account_assertion(Info, Unrealized_Gains_Currency_Movement_Account, -Unrealized_Currency_Gain_Total),

	/*
		BS cross-check
	*/
	writeln("BS cross-check"),
	Financial_Investments_Value is PDRC_Cost_Total + Gain_Total - SDRC_Value_Total,
	writeln(Financial_Investments_Value is PDRC_Cost_Total + Gain_Total - SDRC_Value_Total),
	account_assertion(Info, 'Financial_Investments', Financial_Investments_Value),

	%writeln(Unrealized_PDRC_Cost_Total + Unrealized_Gain_Total),
	%writeln(Bank_Value is Realized_Gain_Total - PDPC_Cost_Total),
	%todo
	writeln(""),

	/*
		Bank account currency movement cross-check
	*/
	writeln(("Bank account currency movement cross-check",(Bank_Value is SDRC_Value_Total - PDRC_Cost_Total))),
	
	Bank_Value is SDRC_Value_Total - PDRC_Cost_Total,
	account_by_role(Accounts1, 'Banks'/'Bank',Bank_Account),
	account_by_role(Accounts1, 'Currency_Movement'/'Bank', Bank_Currency_Account),
	account_vector(Info, Bank_Currency_Account, [Bank_Currency_Movement_Coord]),
	
	number_coord(report_currency, Bank_Currency_Movement_Number, Bank_Currency_Movement_Coord),
	%writeln(Expected_Bank_Value_With_Currency_Movement is Bank_Value - Bank_Currency_Movement_Number),
	Expected_Bank_Value_With_Currency_Movement is Bank_Value - Bank_Currency_Movement_Number,
	account_assertion(Info, Bank_Account, Expected_Bank_Value_With_Currency_Movement),
	writeln(""),

	/*
		debug printout
	*/
	profitandloss_between(Exchange_Rates, Accounts1, Transactions, [report_currency], Report_Date, date(2000,1,1), Report_Date, ProftAndLoss),
	format_report_entries(xbrl, Accounts1, 0, [report_currency], Report_Date, ProftAndLoss, [], _, [], ProftAndLoss_Lines),
	writeln('<!--'),
	writeln(ProftAndLoss_Lines),
	writeln('-->'),
	balance_sheet_at(Exchange_Rates, Accounts1, Transactions, [report_currency], Report_Date, date(2000,1,1), Report_Date, Balance_Sheet),
	format_report_entries(xbrl, Accounts1, 0, [report_currency], Report_Date, Balance_Sheet, [], _, [], Balance_Sheet_Lines),
	writeln('<!--'),
	writeln(Balance_Sheet_Lines),
	writeln('-->').




	% member(exchange_rate(Report_Start_Date, report_currency, Currency_Unique, Original_Exchange_Rate), Exchange_Rates),
	% member(exchange_rate(Report_Date, report_currency, Bank_Currency, Current_Exchange_Rate), Exchange_Rates),
	% Amount is Realized_Gain_Total - Unrealized_PDPC_Cost_Total,
	% Bank_Currency_Account_Value is (Current_Exchange_Rate - Original_Exchange_Rate)*Amount,
	% account_assertion(Info, Bank_Currency_Account, Bank_Currency_Account_Value),
	%account_vector(Info, Bank_Account, Bank_Balance),
	%number_coord(report_currency, Bank_Balance_With_Currency_Movement_Number, Bank_With_Currency_Movement_Coord),
	%assertion(floats_close_enough2('bank total', actual(Bank_Balance_With_Currency_Movement_Number), expected(Bank_Value))),
	%account_assertion(Info, Bank_Account, Bank_Value 



print_totals(Totals) :-
	Totals = (
		Realized_Currency_Gain_Total,
		Realized_Market_Gain_Total,
		Unrealized_Currency_Gain_Total,
		Unrealized_Market_Gain_Total,
		_Unrealized_Gain_Total,
		_Gain_Total,
		_PDRC_Cost_Total,
		_PDPC_Cost_Total,
		_SDRC_Value_Total,
		_Unrealized_PDRC_Cost_Total
	),

	Realized_Gain_Total is Realized_Market_Gain_Total + Realized_Currency_Gain_Total,
writeln(Unrealized_Market_Gain_Total + Unrealized_Currency_Gain_Total),
	Unrealized_Gain_Total is Unrealized_Market_Gain_Total + Unrealized_Currency_Gain_Total,
	Gain_Total is Realized_Gain_Total + Unrealized_Gain_Total,	

	write_float_tag('Realized_Market_Gain_Total',Realized_Market_Gain_Total),
	write_float_tag('Realized_Currency_Gain_Total',Realized_Currency_Gain_Total),
	write_float_tag('Realized_Gain_Total',Realized_Gain_Total),
	write_float_tag('Unrealized_Market_Gain_Total',Unrealized_Market_Gain_Total),
	write_float_tag('Unrealized_Currency_Gain_Total',Unrealized_Currency_Gain_Total),
	write_float_tag('Unrealized_Gain_Total',Unrealized_Gain_Total),
	write_float_tag('Gain_Total',Gain_Total).

write_float_tag(Name, Value) :-
	format(string(String), '~2f', [Value]),
	write_tag(Name, String).


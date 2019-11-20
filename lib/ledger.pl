:- module(ledger, [
		find_s_transactions_in_period/4,
		process_ledger/20
	]).

:- use_module('system_accounts', [
		traded_units/2,
		generate_system_accounts/3]).
:- use_module('accounts').
:- use_module('statements', [
		s_transaction_day/2,
		preprocess_s_transactions/6,
		s_transactions_up_to/3]).
:- use_module('days', [
		format_date/2, 
		parse_date/2, 
		gregorian_date/2, 
		add_days/3,
		date_between/3
]).
:- use_module('utils', [
		pretty_term_string/2,
		dict_json_text/2
]).
:- use_module('livestock', [
		livestock_counts/6
]). 
:- use_module('transactions', [
		check_transaction_account/2,
		transactions_by_account/2
]).
:- use_module('ledger_report', [
		trial_balance_between/8
]).
:- use_module('pacioli', [
		coord_is_almost_zero/1,
		number_vec/3
]).
:- use_module('exchange', [
		vec_change_bases/5
]).

:- use_module(library(rdet)).

:- rdet(generate_gl_data/6).
:- rdet(make_gl_entry/4).
:- rdet(transaction_to_dict/2).
:- rdet(transaction_with_converted_vector/4).

find_s_transactions_in_period(S_Transactions, Opening_Date, Closing_Date, Out) :-
	findall(
		S_Transaction,
		(
			member(S_Transaction, S_Transactions),
			s_transaction_day(S_Transaction, Date),
			date_between(Opening_Date, Closing_Date, Date)
		),
		Out
	).

process_ledger(
	Cost_Or_Market, 
	Livestock_Doms, 
	S_Transactions0, 
	Processed_S_Transactions,
	Start_Date, 
	End_Date, 
	Exchange_Rates0, 
	Report_Currency, 
	Livestock_Types, 
	Livestock_Opening_Costs_And_Counts, 
	Accounts_In, 
	Accounts, 
	Transactions_With_Livestock,
	Transactions_By_Account,
	Transaction_Transformation_Debug,
	Outstanding_Out,
	Processed_Until,
	Warnings,
	Errors,
	Gl
) :-

	gather_ledger_warnings(S_Transactions0, Start_Date, End_Date, Warnings0),
	writeln('<!-- '),
	writeq(Warnings0),
	writeln(' -->'),

	s_transactions_up_to(End_Date, S_Transactions0, S_Transactions),
	pretty_term_string(Exchange_Rates0, Message1b),
	pretty_term_string(Accounts_In, Message3),
	atomic_list_concat([
	'\n<!--',
	'Exchange rates extracted:\n', Message1b,'\n\n',
	'Accounts extracted:\n',Message3,'\n\n',
	'-->\n\n'], Debug_Message0),
	writeln(Debug_Message0),

	/*TODO: if there are no unit values, force Cost_Or_Market = cost?*/
	(
		Cost_Or_Market = cost
	->
		filter_out_market_values(S_Transactions, Exchange_Rates0, Exchange_Rates)
	;
		Exchange_Rates0 = Exchange_Rates
	),
	
	generate_system_accounts((S_Transactions, Livestock_Types), Accounts_In, Generated_Accounts_Nested),
	flatten(Generated_Accounts_Nested, Generated_Accounts),
	pretty_term_string(Generated_Accounts, Message3b),
	atomic_list_concat([
	'\n<!--',
	'Generated accounts:\n', Message3b,'\n\n',
	'-->\n\n'], Debug_Message10),
	writeln(Debug_Message10),
	flatten([Accounts_In, Generated_Accounts], Accounts),
	%check_accounts(Accounts)
	maplist(accounts:check_account_parent(Accounts), Accounts), 
	accounts:write_accounts_json_report(Accounts),
	
	dict_from_vars(Static_Data0, [Accounts, Report_Currency, Start_Date, End_Date, Exchange_Rates, Cost_Or_Market]),
	
	preprocess_s_transactions(Static_Data0, S_Transactions, Processed_S_Transactions, Transactions0, Outstanding_Out, Transaction_Transformation_Debug),
	
	(
		S_Transactions = Processed_S_Transactions
	-> 
		(
			Processed_Until = End_Date,
			Last_Good_Day = End_Date
		)
	;
		(
			last(Processed_S_Transactions, Last_Processed_S_Transaction),
			s_transaction_day(Last_Processed_S_Transaction, Date),
			% todo we could/should do: Processed_Until = with_note(Date, 'until error'),
			Processed_Until = Date,
			add_days(Date, -1, Last_Good_Day)
		)
	),
	flatten(Transactions0, Transactions1),
	
	livestock:process_livestock(Livestock_Doms, Livestock_Types, Processed_S_Transactions, Transactions1, Livestock_Opening_Costs_And_Counts, Start_Date, Last_Good_Day, Exchange_Rates, Accounts, Report_Currency, Transactions_With_Livestock, Livestock_Events, Average_Costs, Average_Costs_Explanations, Livestock_Counts),

	/*
	
	this is probably the right place to plug in hirepurchase and depreciation,
	take Transactions_With_Livestock and produce an updated list.
	notes:
	transaction term now carries date() instead of absolute days count.
	transactions are produced with transactions:make_transaction.
	account id is obtained like this: accounts:account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID).
	to be explained:
		how to get balance on account
		how to generate and return json+html reports
		
	*/

	maplist(check_transaction_account(Accounts), Transactions_With_Livestock),

	atomic_list_concat(Transaction_Transformation_Debug, Message10),
	(
		Livestock_Doms = []
	->
		Livestock_Debug = ''
	;
		(
			pretty_term_string(Livestock_Events, Message0b),
			pretty_term_string(Transactions_With_Livestock, Message1),
			pretty_term_string(Livestock_Counts, Message12),
			pretty_term_string(Average_Costs, Message5),
			pretty_term_string(Average_Costs_Explanations, Message5b),

			atomic_list_concat([
				'Livestock Events:\n', Message0b,'\n\n',
				'Livestock Counts:\n', Message12,'\n\n',
				'Average_Costs:\n', Message5,'\n\n',
				'Average_Costs_Explanations:\n', Message5b,'\n\n',
				'Transactions_With_Livestock:\n', Message1,'\n\n'
			], Livestock_Debug)
		)
	),
	atomic_list_concat([
			'\n<!--',
			Livestock_Debug,
			'Transaction_Transformation_Debug:\n', Message10,'\n\n',
			'-->\n\n'
		], Debug_Message),
	writeln(Debug_Message),


	Static_Data2 = Static_Data0.put(end_date, Processed_Until).put(transactions, Transactions_With_Livestock),
	generate_gl_data(
		Static_Data2, 
		Processed_S_Transactions, 
		/* list of lists */
		Transactions0, 
		/* flat list */
		Transactions1, 
		/* flat list also with livestock transactions */
		Transactions_With_Livestock, 
		/* output */
		Gl),
	transactions_by_account(Static_Data2, Transactions_By_Account),
	trial_balance_between(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, End_Date, Start_Date, End_Date, [Trial_Balance_Section]),
	(
		(
			trial_balance_ok(Trial_Balance_Section)
		;
			Report_Currency = []
		)
	->
		Warnings1 = []
	;
		(
			term_string(trial_balance(Trial_Balance_Section), Tb_Str),
			Warnings1 = ['SYSTEM_WARNING':Tb_Str]
		)
	),
	gather_ledger_errors(Transaction_Transformation_Debug, Errors),
	flatten([Warnings0, Warnings1], Warnings),
	writeln('<!-- '),
	writeq(Warnings),
	writeq(Errors),
	writeln(' -->').

generate_gl_data(Sd, Processed_S_Transactions, Transactions0, Transactions1, Transactions_With_Livestock, Report_Dict) :-
	
	/* extract Livestock_Transactions from Transactions_With_Livestock */
	append(Transactions1, Livestock_Transactions, Transactions_With_Livestock),
	
	/* Outputs list is lists of generated transactions */
	append(Transactions0, [Livestock_Transactions], Outputs),
	
	/* Sources list is all the s_transactions + livestock adjustment transactions */
	append(Processed_S_Transactions, ['livestock'], Sources),

	maplist(make_gl_entry(Sd), Sources, Outputs, Report_Dict).

make_gl_entry(Sd, Source, Transactions, Entry) :-
	Entry = _{source: S, transactions: T},
	(
		atom(Source)
	-> 
		S = Source
	; 
		(
			statements:s_transaction_to_dict(Source, S0),
			/* currently this is converted at transaction date */
			s_transaction_with_transacted_amount(Sd, S0, S)
		)
	),
	maplist(transaction_to_dict, Transactions, T0),
	maplist(transaction_with_converted_vector(Sd), T0, T).
	
s_transaction_with_transacted_amount(Sd, D1, D2) :-
	D2 = D1.put([
		report_currency_transacted_amount_converted_at_transaction_date, AmountA,report_currency_transacted_amount_converted_at_transaction_date, AmountB]),
	vec_change_bases(Sd.exchange_rates, D1.date, Sd.report_currency, D1.vector, Vector_ConvertedA),
	number_vec(_, AmountA0, Vector_ConvertedA),
	AmountA is float(abs(AmountA0)),
	vec_change_bases(Sd.exchange_rates, Sd.end_date, Sd.report_currency, D1.vector, Vector_ConvertedB),
	number_vec(_, AmountB0, Vector_ConvertedB),
	AmountB is float(abs(AmountB0)).

transaction_with_converted_vector(Sd, Transaction, Transaction_Converted) :-
	Transaction_Converted = Transaction.put([
		vector_converted_at_transaction_date=Vector_ConvertedA,
		vector_converted_at_end_date=Vector_ConvertedB
	]),
	vec_change_bases(Sd.exchange_rates, Transaction.date, Sd.report_currency, Transaction.vector, Vector_ConvertedA),
	vec_change_bases(Sd.exchange_rates, Sd.end_date, Sd.report_currency, Transaction.vector, Vector_ConvertedB).
		
trial_balance_ok(Trial_Balance_Section) :-
	Trial_Balance_Section = entry(_, Balance, [], _),
	maplist(coord_is_almost_zero, Balance).
	
gather_ledger_warnings(S_Transactions, Start_Date, End_Date, Warnings) :-
	(
		find_s_transactions_in_period(S_Transactions, Start_Date, End_Date, [])
	->
		Warnings = ['WARNING':'no transactions within request period']
	;
		Warnings = []
	).
	
gather_ledger_errors(Debug, Errors) :-
	(
		(
			last(Debug, Last),
			Last \== 'done.'
		)
	->
		Errors = ['ERROR':Last]		
	;
		Errors = []
	).

filter_out_market_values(S_Transactions, Exchange_Rates0, Exchange_Rates) :-
	traded_units(S_Transactions, Units),
	findall(
		R,
		(
			member(R, Exchange_Rates0),
			R = exchange_rate(_, Src, Dst, _),
			\+member(Src, Units),
			\+member(Dst, Units)
		),
		Exchange_Rates
	).
			
	
	
	

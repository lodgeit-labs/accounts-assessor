:- module(ledger, [
		find_s_transactions_in_period/4,
		process_ledger/14,
		emit_ledger_warnings/3,
		emit_ledger_errors/1]).

:- use_module('system_accounts', [
		generate_system_accounts/3]).
:- use_module('statements', [
		s_transaction_day/2,
		preprocess_s_transactions/5]).
:- use_module('days', [
		format_date/2, 
		parse_date/2, 
		gregorian_date/2, 
		date_between/3]).
:- use_module('utils', [
		pretty_term_string/2,
		coord_is_almost_zero/1]).
:- use_module('livestock', [
		process_livestock/14,
		livestock_counts/6]). 
:- use_module('transactions', [
		check_transaction_account/2]).
:- use_module('ledger_report', [
		trial_balance_between/8
		]).

		
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
	Livestock_Doms, 
	S_Transactions, 
	Start_Days, 
	End_Days, 
	Exchange_Rates, 
	Action_Taxonomy, 
	Report_Currency, 
	Livestock_Types, 
	Livestock_Opening_Costs_And_Counts, 
	Account_Hierarchy_In, 
	Account_Hierarchy, 
	Transactions_With_Livestock,
	Transaction_Transformation_Debug,
	Outstanding_Out
) :-
	emit_ledger_warnings(S_Transactions, Start_Days, End_Days),
	pretty_term_string(Exchange_Rates, Message1b),
	pretty_term_string(Action_Taxonomy, Message2),
	pretty_term_string(Account_Hierarchy_In, Message3),
	atomic_list_concat([
	'\n<!--',
	'Exchange rates extracted:\n', Message1b,'\n\n',
	'Action_Taxonomy extracted:\n',Message2,'\n\n',
	'Account_Hierarchy extracted:\n',Message3,'\n\n',
	'-->\n\n'], Debug_Message0),
	writeln(Debug_Message0),
	
	generate_system_accounts((S_Transactions, Livestock_Types, Action_Taxonomy), Account_Hierarchy_In, Generated_Accounts_Nested),
	flatten(Generated_Accounts_Nested, Generated_Accounts),
	pretty_term_string(Generated_Accounts, Message3b),
	atomic_list_concat([
	'\n<!--',
	'Generated accounts:\n', Message3b,'\n\n',
	'-->\n\n'], Debug_Message10),
	writeln(Debug_Message10),
	flatten([Account_Hierarchy_In, Generated_Accounts], Account_Hierarchy),
	
	preprocess_s_transactions((Account_Hierarchy, Report_Currency, Action_Taxonomy, End_Days, Exchange_Rates), S_Transactions, Transactions1, Outstanding_Out, Transaction_Transformation_Debug),
		
	/*if processing s_transactions failed, we should either limit the end date for livestock processing, 
	or we should filter the additional transactions out before creating reports*/
	
	process_livestock(Livestock_Doms, Livestock_Types, S_Transactions, Transactions1, Livestock_Opening_Costs_And_Counts, Start_Days, End_Days, Exchange_Rates, Account_Hierarchy, Report_Currency, Transactions_With_Livestock, Livestock_Events, Average_Costs, Average_Costs_Explanations),

	livestock_counts(Account_Hierarchy, Livestock_Types, Transactions_With_Livestock, Livestock_Opening_Costs_And_Counts, End_Days, Livestock_Counts),

	maplist(check_transaction_account(Account_Hierarchy), Transactions_With_Livestock),
	
	pretty_term_string(Livestock_Events, Message0b),
	pretty_term_string(Transactions_With_Livestock, Message1),
	pretty_term_string(Livestock_Counts, Message12),
	pretty_term_string(Average_Costs, Message5),
	pretty_term_string(Average_Costs_Explanations, Message5b),
	atomic_list_concat(Transaction_Transformation_Debug, Message10),

	(
		Livestock_Doms = []
	->
		Livestock_Debug = ''
	;
		atomic_list_concat([
			'Livestock Events:\n', Message0b,'\n\n',
			'Livestock Counts:\n', Message12,'\n\n',
			'Average_Costs:\n', Message5,'\n\n',
			'Average_Costs_Explanations:\n', Message5b,'\n\n',
			'Transactions_With_Livestock:\n', Message1,'\n\n'
		], Livestock_Debug)
	),
	
	(
	%Debug_Message = '',!;
	atomic_list_concat([
	'\n<!--',
	%	'S_Transactions:\n', Message0,'\n\n',
	Livestock_Debug,
	'Transaction_Transformation_Debug:\n', Message10,'\n\n',
	'-->\n\n'], Debug_Message)
	),
	writeln(Debug_Message),
	
	trial_balance_between(Exchange_Rates, Account_Hierarchy, Transactions_With_Livestock, Report_Currency, End_Days, Start_Days, End_Days, [Trial_Balance_Section]),
	(
		trial_balance_ok(Trial_Balance_Section)
	->
		true
	;
		write('<!-- SYSTEM_WARNING: trial balance: '), write(Trial_Balance_Section), writeln('-->\n')
	),
	emit_ledger_warnings(S_Transactions, Start_Days, End_Days),
	emit_ledger_errors(Transaction_Transformation_Debug).

trial_balance_ok(Trial_Balance_Section) :-
	Trial_Balance_Section = entry(_, Balance, [], _),
	maplist(coord_is_almost_zero, Balance).
	
emit_ledger_warnings(S_Transactions, Start_Days, End_Days) :-
	(
		find_s_transactions_in_period(S_Transactions, Start_Days, End_Days, [])
	->
		writeln('<!-- WARNING: no transactions within request period -->\n')
	;
		true
	).
	
emit_ledger_errors(Debug) :-
	(
		(
			last(Debug, Last),
			Last \== 'done.'
		)
	->
		format('<!-- ERROR: ~w -->\n', [Last])		
	;
		true
	).

	

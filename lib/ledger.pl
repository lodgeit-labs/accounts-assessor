:- module(ledger, [
		find_s_transactions_in_period/4,
		process_ledger/13,
		emit_ledger_warnings/3]).

:- use_module('system_accounts', [
		generate_system_accounts/3]).
:- use_module('statements', [
		s_transaction_day/2,
		preprocess_s_transactions/4]).
:- use_module('days', [
		format_date/2, 
		parse_date/2, 
		gregorian_date/2, 
		date_between/3]).
:- use_module('utils', [
		pretty_term_string/2]).
:- use_module('livestock', [
		process_livestock/14,
		livestock_counts/5]). 
:- use_module('transactions', [
		check_transaction_account/2]).

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
	Debug_Message, 
	Account_Hierarchy_In, 
	Account_Hierarchy, 
	Transactions_With_Livestock
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
	
	generate_system_accounts((S_Transactions, Livestock_Types, Action_Taxonomy), Account_Hierarchy_In, Generated_Accounts),
	flatten([Account_Hierarchy_In, Generated_Accounts], Account_Hierarchy),
	preprocess_s_transactions((Account_Hierarchy, Report_Currency, Action_Taxonomy, End_Days, Exchange_Rates), S_Transactions, Transactions1, Transaction_Transformation_Debug),
	process_livestock(Livestock_Doms, Livestock_Types, S_Transactions, Transactions1, Livestock_Opening_Costs_And_Counts, Start_Days, End_Days, Exchange_Rates, Account_Hierarchy, Report_Currency, Transactions_With_Livestock, Livestock_Events, Average_Costs, Average_Costs_Explanations),

	livestock_counts(Livestock_Types, Transactions_With_Livestock, Livestock_Opening_Costs_And_Counts, End_Days, Livestock_Counts),

	maplist(check_transaction_account(Account_Hierarchy), Transactions_With_Livestock),
	
	pretty_term_string(Generated_Accounts, Message1a),
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
			'Generated_Accounts:\n', Message1a,'\n\n',
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
	writeln(Debug_Message).
	
	
emit_ledger_warnings(S_Transactions, Start_Days, End_Days) :-
	(
		find_s_transactions_in_period(S_Transactions, Start_Days, End_Days, [])
	->
		writeln('<!-- WARNING: no transactions within request period -->\n')
	;
		true
	).

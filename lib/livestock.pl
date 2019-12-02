% see also doc/ledger-livestock
/*TODO:beginning and ending dates in livestockData are missing/ignored*/

:- module(livestock, []).
:- use_module(library(xbrl/utils), [
	user:goal_expansion/2,
	pretty_term_string/2,
	maplist6/6,
	throw_string/1
]).
:- use_module('pacioli', [
	vec_add/3,
	vec_inverse/2,
	vec_reduce/2,
	vec_sub/3,
	number_coord/3
]).
:- use_module('accounts', [
	account_in_set/3,
	account_by_role/3
]).
:- use_module('days', [
	parse_date/2
]).
:- use_module(library(semweb/rdf11)).
:- use_module('doc', [
	doc/3
]).
:- use_module('ledger_report', [
	balance_by_account/9
]).
:- use_module('transactions', [
	make_transaction/5,
	transactions_by_account/2
]).
:- use_module('s_transaction', []).

:- use_module(library(rdet)).

:- ['livestock_accounts', 'livestock_average_cost', 'livestock_crosscheck', 'livestock_misc', 'livestock_adjustment_transactions', 'livestock_extract'].

:- use_module('bank_statement', []).


:- rdet(preprocess_livestock_buy_or_sell/3).

livestock_data(Uri) :-
	doc(Uri, rdf:a, l:livestock_data).

livestock_data_by_vector_unit(Livestock, Exchanged) :-
	pacioli:vector_unit(Exchanged, Unit),
	findall(
		L,
		(
			livestock_data(L),
			doc(L, livestock:name, Unit/*?*/)
		),
		Known_Livestock_Datas
	),
	length(Known_Livestock_Datas, Known_Livestock_Datas_Length),
	(   Known_Livestock_Datas_Length > 1
	->  utils:throw_string(multiple_livestock_types_match)
	;   true),
	(	Known_Livestock_Datas_Length = 0
	->	(
			findall(U,(livestock_data(L),doc(L, livestock:name, U)),Units),
			format(user_error, 'WARNING:looking for livestock unit ~q, known units: ~q', [Unit, Units])
		)
	;	true),
	[Livestock] = Known_Livestock_Datas.

infer_livestock_action_verb(S_Transaction, NS_Transaction) :-
	s_transaction:s_transaction_type_id(S_Transaction, ''),
	s_transaction:s_transaction_type_id(NS_Transaction, uri(Action_Verb)),
	/* just copy these over */
	s_transaction:s_transaction_exchanged(S_Transaction, vector(Exchanged)),
	s_transaction:s_transaction_exchanged(NS_Transaction, vector(Exchanged)),
	s_transaction:s_transaction_day(S_Transaction, Transaction_Date),
	s_transaction:s_transaction_day(NS_Transaction, Transaction_Date),
	s_transaction:s_transaction_vector(S_Transaction, Vector),
	s_transaction:s_transaction_vector(NS_Transaction, Vector),
	s_transaction:s_transaction_account_id(S_Transaction, Unexchanged_Account_Id),
	s_transaction:s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id),
	/* if.. */
	livestock_data_by_vector_unit(_,Exchanged),
	(	pacioli:is_debit(Vector)
	->	Action_Verb = l:livestock_sale
	;	Action_Verb = l:livestock_purchase).

s_transaction_is_livestock_buy_or_sell(S_Transaction, Date, Livestock_Type, Livestock_Coord, Money_Coord) :-
	S_Transaction = s_transaction(Date, uri(Action_Verb), [Money_Coord], _, vector(V)),
	(Action_Verb = l:livestock_purchase;Action_Verb = l:livestock_sale),
	!,
	V = [Livestock_Coord],
	pacioli:coord_unit(Livestock_Coord, Livestock_Type),
	livestock_data_by_vector_unit(_, V).

preprocess_livestock_buy_or_sell(Static_Data, S_Transaction, [Bank_Txs, Livestock_Count_Transaction, Pl_Transaction]) :-
	%gtrace,
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Money_Coord),
	(   pacioli:is_debit(Money_Coord)
	->  Description = 'livestock sale'
	;   Description = 'livestock purchase'),
	count_account(Livestock_Type, Count_Account),
	make_transaction(Day, Description, Count_Account, [Livestock_Coord], Livestock_Count_Transaction),
	bank_statement:affect_bank_account(Static_Data, S_Transaction, Description, Bank_Txs),
	(   pacioli:is_credit(Money_Coord)
	->	(
			cogs_account(Livestock_Type, Cogs_Account),
			pacioli:vec_inverse([Money_Coord], Expense_Vector),
			make_transaction(Day, 'livestock buy', Cogs_Account, Expense_Vector, Pl_Transaction)
		)
	;
		(
			sales_account(Livestock_Type, Sales_Account),
			make_transaction(Day, Description, Sales_Account, [Money_Coord], Pl_Transaction)
		)
	).

process_livestock(Info, Livestock_Transactions) :-
	findall(
		Txs,
		(
			livestock_data(L),
			(	process_livestock2(Info, L, Txs)
			->	true
			;	(gtrace,utils:throw_string('process_livestock2 failed'))
			)
		),
		Txs_List
	),
	flatten(Txs_List, Livestock_Transactions).

process_livestock2((S_Transactions, Transactions_In), Livestock, Transactions_Out) :-
	/*
	todo send livestock dates from excel and check them here
	*/
	doc:request_has_property(l:start_date, Start_Date),
	doc:request_has_property(l:end_date, End_Date),

	/*
	preprocess_livestock_buy_or_sell happens first, as part of preprocess_s_transaction.
	it affects bank account and livestock headcount.
	*/

	/* record opening value in assets */
	opening_inventory_transactions(Livestock, Opening_Inventory_Transactions),
	Transactions1 = Opening_Inventory_Transactions,

	/* born, loss, rations */
	preprocess_headcount_changes(Livestock, Headcount_Change_Transactions),
	append(Transactions1, Headcount_Change_Transactions, Transactions2),
	
	/* avg cost relies on Opening_And_Purchases_And_Increase */
	infer_average_cost(Livestock, S_Transactions),
	doc(Livestock, livestock:average_cost, exchange_rate(_,_,_,XXX)),
	term_string(XXX, XXXX, [attributes(write)]),
	format(user_error, 'XXXX~wXXXX~n', [XXXX]),

	/* rations value is derived from avg cost */
	preprocess_rations(Livestock, Rations_Transactions),
	append(Transactions2, Rations_Transactions, Transactions3),

	/* counts were changed by buys/sells and by rations, losses and borns */
	dict_from_vars(Static_Data0, [Start_Date, End_Date]),
	append(Transactions_In, Transactions3, Transactions_Total),

	doc:request_has_property(l:accounts, Accounts),
	Static_Data1 = Static_Data0.put(transactions,Transactions_Total).put(accounts,Accounts),
	transactions_by_account(Static_Data1, Transactions_By_Account),

	closing_inventory_transactions(Livestock, Transactions_By_Account, Closing_Transactions),
	append(Transactions3, Closing_Transactions, Transactions_Out),

	%maplist(do_livestock_cross_check(Livestock_Events, Natural_Increase_Costs, S_Transactions, Transactions_Out, Opening_Costs_And_Counts, Start_Date, End_Date, Exchange_Rates, Accounts, Report_Currency, Average_Costs), Livestocks)
	true.

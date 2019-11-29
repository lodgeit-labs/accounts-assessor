% see also doc/ledger-livestock
/*TODO:beginning and ending dates are often ignored*/

:- module(livestock, [
		get_livestock_types/2,
		process_livestock/15,
		preprocess_livestock_buy_or_sell/3,
		make_livestock_accounts/2,
		livestock_counts/6,
		compute_livestock_by_simple_calculation/23
]).
:- use_module('utils', [
	user:goal_expansion/2,
	inner_xml/3,
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
:- use_module('ledger_report', [
	balance_by_account/9
]).
:- use_module('transactions', [
	make_transaction/5,
	transactions_by_account/2
]).

:- rdet(process_livestock2/x).

livestock_data(Uri) :-
	doc(Uri, rdf:a, l:livestock_data).

find_livestock_data_by_vector_unit(Exchanged) :-
	vector_unit(Exchanged, Unit),
	findall(
		L,
		(
			livestock_data(L),
			my_with_subgraphs(L, livestock:type, Unit/*?*/)
		),
		Known_Livestock_Datas
	),
	length(Known_Livestock_Datas, Known_Livestock_Datas_Length),
	(   Known_Livestock_Datas_Length > 1
	->  throw(xxx)
	;   true).

infer_livestock_action_verb(S_Transaction, NS_Transaction) :-
	gtrace,
	s_transaction_type_id(S_Transaction, ''),
	s_transaction_type_id(NS_Transaction, livestock:trade),
	s_transaction_exchanged(S_Transaction, Exchanged),
	find_livestock_data_by_vector_unit(Exchanged),
	/* just copy these over */
	s_transaction_exchanged(NS_Transaction, Exchanged).
	s_transaction_day(S_Transaction, Transaction_Date),
	s_transaction_day(NS_Transaction, Transaction_Date),
	s_transaction_vector(S_Transaction, Vector),
	s_transaction_vector(NS_Transaction, Vector),
	s_transaction_account_id(S_Transaction, Unexchanged_Account_Id),
	s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id).

s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Money_Coord) :-
	S_Transaction = s_transaction(Day, '', [Money_Coord], Unexchanged_Account_Id, vector([Livestock_Coord])),
	coord_unit(Livestock_Coord, Livestock_Type),
	livestock_data(Livestock),
	doc(Livestock, livestock:name, Livestock_Type).

preprocess_livestock_buy_or_sell(Static_Data, S_Transaction, [Bank_Txs, Livestock_Count_Transaction, Pl_Transaction]) :-
	dict_vars(Static_Data, [Accounts]),
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Money_Coord),
	(   is_debit(Money_Coord)
	->  Description = 'livestock sale'
	;   Description = 'livestock purchase'),
	count_account(Livestock_Type, Count_Account),
	make_transaction(Day, Description, Count_Account, [Livestock_Coord], Livestock_Count_Transaction),
	affect_bank_account(Static_Data, S_Transaction, Description, Bank_Txs)
	(   MoneyDebit > 0
	->	(
			cogs_account(Livestock_Type, Cogs_Account),
			make_transaction(Day, 'livestock buy', Cogs_Account, Expense_Vector, Pl_Transaction)
		)
	;
		(
			sales_account(Livestock_Type, Sales_Account),
			make_transaction(Day, Description, Sales_Account, Bank_Vector, Pl_Transaction)
		)
	).

process_livestock2(S_Transactions, Transactions_In, Start_Date, End_Date, Accounts, Transactions_Out, Livestock) :-

	/*
	preprocess_livestock_buy_or_sell happens first, as part of preprocess_s_transaction.
	it affects bank account and livestock headcount.
	*/

	/* record opening value in assets */
	opening_inventory_transactions(Livestock, Start_Date, Opening_Inventory_Transactions),
	append(Transactions_In, Opening_Inventory_Transactions, Transactions1),

	/* born, loss, rations */
	preprocess_headcount_changes(Livestock, End_Date, Headcount_Change_Transactions),
	append(Transactions1, Headcount_Change_Transactions, Transactions2),

	/* avg cost relies on Opening_And_Purchases_And_Increase */
	infer_average_cost(Livestock, Start_Date, End_Date, S_Transactions),

	/* rations value is derived from avg cost */
	preprocess_rations(Livestock, Date, Rations_Transactions) :-
	append(Transactions2, Rations_Transactions, Transactions3),

	/* counts were changed by buys/sells and by rations, losses and borns */
	dict_from_vars(Static_Data0, [Start_Date, End_Date]),
	Static_Data1 = Static_Data0.put(transactions,Transactions3),
	transactions_by_account(Static_Data1, Transactions_By_Account),

	closing_inventory_transactions(Livestocks, End_Date, Transactions_By_Account, Closing_Transactions),
	append(Transactions3, Closing_Transactions, Transactions_Out),

	%maplist(do_livestock_cross_check(Livestock_Events, Natural_Increase_Costs, S_Transactions, Transactions_Out, Opening_Costs_And_Counts, Start_Date, End_Date, Exchange_Rates, Accounts, Report_Currency, Average_Costs), Livestocks)
	true.
	

process_livestock(Livestock_Types, S_Transactions, Transactions_In, Start_Date, End_Date, Accounts, _Report_Currency, Transactions_Out) :-
	findall(
		Ts,
		(
			livestock_data(L),
			process_livestock2(L, Ts)
		),
		Transactions_Out
	).


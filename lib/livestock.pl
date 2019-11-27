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

find_livestock_data_by_vector_unit(Exchanged) :-
	vector_unit(Exchanged, Unit),
	findall(
		L,
		(
			my_with_subgraphs(L, rdf:a, l:livestock_data),
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

s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Bank_Vector, Our_Vector, Unexchanged_Account_Id, Our_Debit, Our_Credit) :-
	S_Transaction = s_transaction(Day, '', Our_Vector, Unexchanged_Account_Id, Exchanged),
	vector([Livestock_Coord]) = Exchanged,
	coord(Livestock_Type, _, _) = Livestock_Coord,
	% member(Livestock_Type, Livestock_Types),
	% bank statements are from the perspective of the bank, their debit is our credit
	vec_inverse(Bank_Vector, Our_Vector),
	[coord(_, Our_Debit, Our_Credit)] = Our_Vector.

preprocess_livestock_buy_or_sell(Static_Data, S_Transaction, [Bank_Transaction, Livestock_Transaction]) :-
	dict_vars(Static_Data, [Accounts]),
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, _, _, _, MoneyDebit, _),
	(   MoneyDebit > 0
	->  Description = 'livestock sale'
	;   Description = 'livestock purchase'),
	count_account(Livestock_Type, Count_Account),
	make_transaction(Day, Description, Count_Account, [Livestock_Coord], Livestock_Count_Transaction),
	affect_bank_account(Static_Data, S_Transaction, Description, Ts1)
	?
	?
	cogs_account(Livestock_Type, Cogs_Account),
	make_transaction(Day, 'livestock buy', Cogs_Account, Expense_Vector, Buy_Transaction).
	?
	?
	sales_account(Livestock_Type, Sales_Account),
	make_transaction(Day, Description, Sales_Account, Bank_Vector, Sale_Transaction),
	?
	?



livestock_counts(Accounts, Livestock_Types, Transactions, Opening_Costs_And_Counts, To_Day, Counts) :-
	findall(
	Count,
	(
		member(Livestock_Type, Livestock_Types),
		member(Opening_Cost_And_Count, Opening_Costs_And_Counts),
		opening_cost_and_count(Livestock_Type, _, _)  = Opening_Cost_And_Count,
		livestock_count(Accounts, Livestock_Type, Transactions, Opening_Cost_And_Count, To_Day, Count)
	),
	Counts).

livestock_count(Accounts, Livestock_Type, Transactions_By_Account, Opening_Cost_And_Count, To_Day, Count) :-
	opening_cost_and_count(Livestock_Type, _, Opening_Count) = Opening_Cost_And_Count,
	count_account(Livestock_Type, Count_Account),
	balance_by_account([], Accounts, Transactions_By_Account, [], _, Count_Account, To_Day, Count_Vector, _),
	vec_add(Count_Vector, [coord(Livestock_Type, Opening_Count, 0)], Count).

livestock_at_average_cost_at_day(Accounts, Livestock_Type, Transactions_By_Account, Opening_Cost_And_Count, To_Day, Average_Cost_Exchange_Rate, Cost_Vector) :-
	livestock_count(Accounts, Livestock_Type, Transactions_By_Account, Opening_Cost_And_Count, To_Day, Count_Vector),
	exchange_rate(_, _, Dest_Currency, Average_Cost) = Average_Cost_Exchange_Rate,
	[coord(_, Count, _)] = Count_Vector,
	Cost is Average_Cost * Count,
	Cost_Vector = [coord(Dest_Currency, Cost, 0)].

yield_livestock_cogs_transactions(
	Accounts, 
	Livestock_Type, 
	Opening_Cost_And_Count, Average_Cost,
	(_From_Day, To_Day, _Average_Costs, Transactions_By_Account, _S_Transactions, Transactions_By_Account),
	Cogs_Transactions
) :-
		livestock_at_average_cost_at_day(Accounts, Livestock_Type, Transactions_By_Account, Opening_Cost_And_Count, To_Day, Average_Cost, Closing_Debit),
		opening_cost_and_count(Livestock_Type, Opening_Cost, _) = Opening_Cost_And_Count,
	
		vec_sub(Closing_Debit, Opening_Cost, Adjustment_Debit),
		vec_inverse(Adjustment_Debit, Adjustment_Credit),
		
		Cogs_Transactions = [T1, T2],
		% expense/revenue
		make_transaction(To_Day, "livestock adjustment", Cogs_Account, Adjustment_Credit, T1),
		% assets
		make_transaction(To_Day, "livestock adjustment", 'AssetsLivestockAtAverageCost', Adjustment_Debit, T2),
		cogs_account(Livestock_Type, Cogs_Account).










livestock_account_ids('Livestock', 'LivestockAtCost', 'Drawings', 'LivestockRations').
expenses__direct_costs__purchases__account_id('Purchases').
cost_of_goods_livestock_account_id('CostOfGoodsLivestock').




preprocess_livestock_event(Event, Transaction) :-
	Event = born(Type, Day, Count),
	count_account(Type, Count_Account),
	make_transaction(Day, 'livestock born', Count_Account, [coord(Type, Count, 0)], Transaction).
	
preprocess_livestock_event(Event, Transaction) :-
	Event = loss(Type, Day, Count),
	count_account(Type, Count_Account),
	make_transaction(Day, 'livestock loss', Count_Account, [coord(Type, 0, Count)], Transaction).
	
preprocess_livestock_event(Event, Transaction) :-
	Event = rations(Type, Day, Count),
	count_account(Type, Count_Account),
	make_transaction(Day, 'livestock rations', Count_Account, [coord(Type, 0, Count)], Transaction).

preprocess_livestock_event(Event, _) :-
	Event = sale(_,_,_).

preprocess_livestock_event(Event, _) :-
	Event = purchase(_,_,_).


	
% natural increase count given livestock type and all livestock events
natural_increase_count(Type, [E | Events], Natural_Increase_Count) :-
	(E = born(Type, _Day, Count) ->
		C = Count;
		C = 0),
	natural_increase_count(Type, Events, Natural_Increase_Count_1),
	Natural_Increase_Count is Natural_Increase_Count_1 + C.
	
natural_increase_count(_, [], 0).



livestock_purchases_cost_and_count(Type, [ST | S_Transactions], Purchases_Cost, Purchases_Count) :-
	(
		(
			s_transaction_is_livestock_buy_or_sell(ST, _Day, Type, Livestock_Coord, _, Vector_Ours, _, _, _),
			Vector_Ours = [coord(_, 0, _)]
		)
		->
		(
			Livestock_Coord = coord(Type, Count, 0),
			Cost = Vector_Ours
		)
		;
		(
			Cost = [], Count = 0
		)
	),
	livestock_purchases_cost_and_count(Type, S_Transactions, Purchases_Cost_2, Purchases_Count_2),
	vec_add(Cost, Purchases_Cost_2, Purchases_Cost),
	Purchases_Count is Purchases_Count_2 + Count.

livestock_purchases_cost_and_count(_, [], [], 0).



/*
The Livestock calculator is an average cost calculator. 
Cost, average cost, market value. 
There may be other ways of measuring value. But any way is simply units held at some time point * defined value. 
Think about what any asset is worth?
Unless you sell it you don't really know
You have to estimate.
*/
average_cost(Type, Opening_Cost0, Opening_Count0, Info, Exchange_Rate) :-
	Info = (_From_Day, _To_Day, S_Transactions, Livestock_Events, Natural_Increase_Costs),
	/*?
	for now, we ignore _From_Day (and _To_Day), 
	and use Opening_Cost and Opening_Count as stated in the request.
	*/
	Exchange_Rate = with_info(exchange_rate(_, Type, Currency, Average_Cost), Explanation),
	Explanation = {formula: Formula_String1, computation: Formula_String2},
	
	compile_with_variable_names_preserved((
		Natural_Increase_Value = Natural_Increase_Cost_Per_Head * Natural_Increase_Count,
		Opening_And_Purchases_And_Increase_Value_Exp = Opening_Value + Purchases_Value + Natural_Increase_Value,
		Opening_And_Purchases_And_Increase_Count_Exp = Opening_Count + Purchases_Count + Natural_Increase_Count,
		Average_Cost_Exp = Opening_And_Purchases_And_Increase_Value_Exp / Opening_And_Purchases_And_Increase_Count_Exp
	),	Names1),
	%	replace_underscores_in_variable_names_with_spaces(Names0, Names1),

	term_string(Average_Cost_Exp, Formula_String1, [Names1]),
	%pretty_term_string(Average_Cost_Exp, Formula_String1, [Namings]),

	% now let's fill in the values
	Opening_Cost = Opening_Cost0,
	Opening_Count = Opening_Count0,
	[coord(Currency, Opening_Value, 0)] = Opening_Cost, 
	member(natural_increase_cost(Type, [coord(Currency, Natural_Increase_Cost_Per_Head, 0)]), Natural_Increase_Costs),
	natural_increase_count(Type, Livestock_Events, Natural_Increase_Count),
	livestock_purchases_cost_and_count(Type, S_Transactions, Purchases_Cost, Purchases_Count),

	(
			Purchases_Cost == []
		->
			Purchases_Value = 0
		;
			[coord(Currency, 0, Purchases_Value)] = Purchases_Cost
	),
	
	pretty_term_string(Average_Cost_Exp, Formula_String2),
	
	% avoid division by zero and evaluate the formula
	Opening_And_Purchases_And_Increase_Count is Opening_And_Purchases_And_Increase_Count_Exp,
	(
		Opening_And_Purchases_And_Increase_Count > 0
	->
		Average_Cost is Average_Cost_Exp
	;
		Average_Cost = 0
	).

vector_single_item([Item], Item).
	



get_average_costs(Livestock_Types, Opening_Costs_And_Counts, Info, Average_Costs) :-
	maplist(get_average_costs2(Opening_Costs_And_Counts, Info), Livestock_Types, Average_Costs).

get_average_costs2(Opening_Costs_And_Counts, Info, Livestock_Type, Rate) :-
	member(opening_cost_and_count(Livestock_Type, Opening_Cost, Opening_Count), Opening_Costs_And_Counts),
	average_cost(Livestock_Type, Opening_Cost, Opening_Count, Info, Rate).
	
get_livestock_cogs_transactions(Accounts, Livestock_Types, Opening_Costs_And_Counts, Average_Costs, Info, Transactions_Out) :-
	findall(Txs, 
		(
			member(Livestock_Type, Livestock_Types),
			
			member(Opening_Cost_And_Count, Opening_Costs_And_Counts),	
			opening_cost_and_count(Livestock_Type, _, _) = Opening_Cost_And_Count,
			member(Average_Cost, Average_Costs),
			exchange_rate(_, Livestock_Type, _, _) = Average_Cost,
			
			yield_livestock_cogs_transactions(
				Accounts,
				Livestock_Type, 
				Opening_Cost_And_Count,
				Average_Cost,
				Info,
				Txs)
		),
		Transactions_Nested),
	flatten(Transactions_Nested, Transactions_Out).




/* we should have probably just put the livestock count accounts under inventory */
yield_livestock_inventory_transaction(Livestock_Type, Opening_Cost_And_Count, Average_Cost_Exchange_Rate, End_Date, Transactions_In, Inventory_Transaction) :-
	livestock_at_average_cost_at_day(Livestock_Type, Transactions_In, Opening_Cost_And_Count, End_Date, Average_Cost_Exchange_Rate, Vector),
	make_transaction(End_Date, 'livestock closing inventory', 'AssetsLivestockAtCost', Vector, Inventory_Transaction).

get_livestock_inventory_transactions(Livestock_Types, Opening_Costs_And_Counts, Average_Costs, End_Date, Transactions_In, Assets_Transactions) :-
	findall(Inventory_Transaction,
	(
		member(Livestock_Type, Livestock_Types),
		member(Opening_Cost_And_Count, Opening_Costs_And_Counts),	
		opening_cost_and_count(Livestock_Type, _, _) = Opening_Cost_And_Count,
		member(Average_Cost, Average_Costs),
		exchange_rate(_, Livestock_Type, _, _) = Average_Cost,
		yield_livestock_inventory_transaction(Livestock_Type, Opening_Cost_And_Count, Average_Cost, End_Date, Transactions_In, Inventory_Transaction)
	),
	Assets_Transactions).


/*TODO transactions_by_account here...*/
process_livestock(Livestock_Doms, Livestock_Types, S_Transactions, Transactions_In, Opening_Costs_And_Counts, Start_Date, End_Date, _Exchange_Rates, Accounts, _Report_Currency, Transactions_Out, Livestock_Events, Average_Costs, Average_Costs_Explanations, Counts) :-
	extract_livestock_events(Livestock_Doms, Livestock_Events),
	extract_natural_increase_costs(Livestock_Doms, Natural_Increase_Costs),

	maplist(opening_inventory_transactions(Start_Date, Opening_Costs_And_Counts), Livestock_Types, Opening_Inventory_Transactions0),
	flatten(Opening_Inventory_Transactions0, Opening_Inventory_Transactions),
	append(Transactions_In, Opening_Inventory_Transactions, Transactions1),

	maplist(preprocess_livestock_event, Livestock_Events, Livestock_Event_Transactions_Nested),
	flatten(Livestock_Event_Transactions_Nested, Livestock_Event_Transactions0),
	exclude(var, Livestock_Event_Transactions0, Livestock_Event_Transactions),
	append(Transactions1, Livestock_Event_Transactions, Transactions2),

	get_average_costs(Livestock_Types, Opening_Costs_And_Counts, (Start_Date, End_Date, S_Transactions, Livestock_Events, Natural_Increase_Costs), Average_Costs_With_Explanations),
	maplist(with_info_value_and_info, Average_Costs_With_Explanations, Average_Costs, Average_Costs_Explanations),
  
	livestock_adjustment_transactions(Livestock_Types, S_Transactions, More_Transactions),
	append(Transactions2, More_Transactions, Transactions3),  

	dict_from_vars(Static_Data0, [Accounts, Start_Date, End_Date]),
	Static_Data1 = Static_Data0.put(transactions,Transactions3),
	transactions_by_account(Static_Data1, Transactions_By_Account),

	get_livestock_cogs_transactions(Accounts, Livestock_Types, Opening_Costs_And_Counts, Average_Costs, (Start_Date, End_Date, Average_Costs, Transactions_By_Account, S_Transactions),  Cogs_Transactions),
	append(Transactions3, Cogs_Transactions, Transactions_Out),

	Static_Data2 = Static_Data1.put(transactions,Transactions_Out),
	transactions_by_account(Static_Data2, Transactions_With_Livestock_By_Account),

	livestock_counts(Accounts, Livestock_Types, Transactions_With_Livestock_By_Account, Opening_Costs_And_Counts, End_Date, Counts),

	%maplist(do_livestock_cross_check(Livestock_Events, Natural_Increase_Costs, S_Transactions, Transactions_Out, Opening_Costs_And_Counts, Start_Date, End_Date, Exchange_Rates, Accounts, Report_Currency, Average_Costs), Livestock_Types)
	true.
	


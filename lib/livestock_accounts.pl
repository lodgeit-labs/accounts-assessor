
/*
create livestock-specific accounts that could be missing in user account hierarchy. This ignores roles for now, fixme
*/
make_livestock_accounts(Livestock_Type, Accounts) :-
	Accounts = [Cogs, CogsRations, Sales, Count],

	cogs_account(Livestock_Type, Cogs_Name),
	sales_account(Livestock_Type, Sales_Name),
	count_account(Livestock_Type, Count_Name),
	cogs_rations_account(Livestock_Type, CogsRations_Name),

	Cogs  = account(Cogs_Name, /*Expenses/ */'CostOfGoodsLivestock', '', 0),
	Sales = account(Sales_Name, /*Revenue/ */'SalesOfLivestock', '', 0),
	Count = account(Count_Name, 'LivestockCount', '', 0),
	CogsRations = account(CogsRations_Name, Cogs_Name, '', 0).

/* fixme look these up by roles */
cogs_account(Livestock_Type, Cogs_Account) :-
	atom_concat(Livestock_Type, 'Cogs', Cogs_Account).

cogs_rations_account(Livestock_Type, Cogs_Rations_Account) :-
	atom_concat(Livestock_Type, 'CogsRations', Cogs_Rations_Account).

sales_account(Livestock_Type, Sales_Account) :-
	atom_concat(Livestock_Type, 'Sales', Sales_Account).

count_account(Livestock_Type, Count_Account) :-
	atom_concat(Livestock_Type, 'Count', Count_Account).



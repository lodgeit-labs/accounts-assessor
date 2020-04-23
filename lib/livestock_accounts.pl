/*
create livestock-specific accounts that are missing in user account hierarchy.
*/

:- comment(code:make_livestock_accounts, code_topics:account_creation, "livestock accounts are created up-front.").

make_livestock_accounts :-
	livestock_units(Units),
	maplist(make_livestock_accounts, Units).

make_livestock_accounts(Livestock_Type, Accounts) :-

	cogs_account_id(Livestock_Type, Cogs_Name),
	sales_account_id(Livestock_Type, Sales_Name),
	count_account_id(Livestock_Type, Count_Name),
	cogs_rations_account_id(Livestock_Type, CogsRations_Name),

	account_by_role_throw('Accounts'/'CostOfGoodsLivestock', CostOfGoodsLivestock),
	account_by_role_throw('Accounts'/'SalesOfLivestock', SalesOfLivestock),

	maybe_make_account(Cogs_Name, CostOfGoodsLivestock, 0, 'CostOfGoodsLivestock'/Livestock_Type, Cogs_uri),
	maybe_make_account(Sales_Name, SalesOfLivestock, 0, 'SalesOfLivestock'/Livestock_Type, _),
	maybe_make_account(Count_Name, LivestockCount, 0, 'LivestockCount'/Livestock_Type, _),
	maybe_make_account(CogsRations_Name, Cogs_uri, 0, ('CostOfGoodsLivestock'/Livestock_Type)/'Rations', _).

cogs_account_id(Livestock_Type, Cogs_Account) :-
	atom_concat(Livestock_Type, 'Cogs', Cogs_Account).

cogs_rations_account_id(Livestock_Type, Cogs_Rations_Account) :-
	atom_concat(Livestock_Type, 'CogsRations', Cogs_Rations_Account).

sales_account_id(Livestock_Type, Sales_Account) :-
	atom_concat(Livestock_Type, 'Sales', Sales_Account).

count_account_id(Livestock_Type, Count_Account) :-
	atom_concat(Livestock_Type, 'Count', Count_Account).


livestock_units(Units) :-
	findall(
		Unit,
		(
			doc(L, rdf:type, l:livestock_data),
			doc(L, livestock:name, Unit)
		),
		Units
	).


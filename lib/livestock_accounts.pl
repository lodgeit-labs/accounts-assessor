/*
create livestock-specific accounts that are missing in user account hierarchy.
*/

%:- comment(code:ensure_livestock_accounts_exist, code_topics:account_creation, "livestock accounts are created up-front.").

ensure_livestock_accounts_exist :-
	livestock_units(Units),
	maplist(ensure_livestock_accounts_exist2, Units).

ensure_livestock_accounts_exist2(Livestock_Type) :-

	cogs_account_id(Livestock_Type, Cogs_Name),
	sales_account_id(Livestock_Type, Sales_Name),
	count_account_id(Livestock_Type, Count_Name),
	cogs_rations_account_id(Livestock_Type, CogsRations_Name),

	account_by_role_throw('Accounts'/'CostOfGoodsLivestock', CostOfGoodsLivestock),
	account_by_role_throw('Accounts'/'SalesOfLivestock', SalesOfLivestock),

	ensure_account_exists(CostOfGoodsLivestock, Cogs_Name, 0, 'CostOfGoodsLivestock'/Livestock_Type, Cogs_uri),
	ensure_account_exists(SalesOfLivestock, Sales_Name, 0, 'SalesOfLivestock'/Livestock_Type, _),
	ensure_account_exists(LivestockCount, Count_Name, 0, 'LivestockCount'/Livestock_Type, _),
	ensure_account_exists(Cogs_uri, CogsRations_Name, 0, 'CostOfGoodsLivestock'/Livestock_Type/'Rations', _).

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


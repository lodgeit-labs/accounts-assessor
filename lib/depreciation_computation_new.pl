:- module(_,[]).

:- use_module(days, [day_diff/3]).
:- asserta(user:file_search_path(library, '../prolog_xbrl_public/xbrl/prolog')).
:- use_module(library(xbrl/utils)).
:- use_module(event_calculus, [depreciationInInterval/13]).
:- use_module('doc', [doc/3]).

begin_accounting_date(date(1990,1,1)).

% Calculates depreciation on a daily basis between the invest in date and any other date
% recurses for every income year, because depreciation rates may be different
depreciation_between_invest_in_date_and_other_date(
		Invest_in_value, 						% value at time of investment/ Asset Cost
		Initial_value, 							% value at start of year / Asset Base Value
		Method, 								% Diminishing Value / Prime Cost
		Purchase_date,
		date(From_year, From_Month, From_day),
		To_date,								% date for which depreciation should be computed
		Account,								% Asset or pool (pool is an asset in the account taxonomy)
		Depreciation_year, 						% 1,2,3...
		Effective_life_years,
		Initial_depreciation_value,
		Total_depreciation_value
	):-
	day_diff(date(From_year, From_Month, From_day), To_date, Days_difference),
	check_day_difference_validity(Days_difference),	
	begin_accounting_date(Begin_accounting_date),
	day_diff(Begin_accounting_date, date(From_year, From_Month, 1), T1),
	% Get days From date until end of the current income year, <=365
	(
		From_Month < 7
		-> 
			day_diff(date(From_year, From_Month, From_day), date(From_year, 7, 1), Days_held),
			Next_from_year is From_year
			;
			day_diff(date(From_year, From_Month, From_day), date(From_year + 1, 7, 1), Days_held),
			Next_from_year is From_year + 1
	),
	(
		Days_difference < Days_held
			-> 
			T2 is T1 + Days_difference,
			depreciationInInterval(Account,Invest_in_value,Purchase_date,T1,T2,Initial_value,_,Method,
				Depreciation_year,Effective_life_years,_,0,Depreciation_value),
			Total_depreciation_value is Initial_depreciation_value + Depreciation_value
	;
			T2 is T1 + 365,
			depreciationInInterval(Account,Invest_in_value,Purchase_date,T1,T2,Initial_value,_,Method,
				Depreciation_year,Effective_life_years,_,0,Depreciation_value),
			Next_depreciation_year is Depreciation_year + 1,
			Next_initial_value is Initial_value - Depreciation_value,
			Next_depreciation_value is (Initial_depreciation_value + Depreciation_value),
			depreciation_between_invest_in_date_and_other_date(
				Invest_in_value, 
				Next_initial_value, 
				Method,
				Purchase_date,
				date(Next_from_year, 7, 1), 
				To_date, 
				Account,

				Next_depreciation_year, 
				Effective_life_years, 
				Next_depreciation_value,
				Total_depreciation_value
			)
	).

%start:-depreciationInInterval(corolla,76768,date(2019,7,1),0,32,76768,_,diminishing_value,1,5,_,0,Depreciation_value).
/*start:-depreciation_between_invest_in_date_and_other_date(76768,76768,diminishing_value,date(2017,1,1),date(2017,1,1),date(2017,7,2),corolla,_,1,5,0,_Result).*/

% List of available pools
pool(general_pool).
pool(software_pool).
pool(low_value_pool).

% Calculates depreciation between any two dates on a daily basis equal or posterior to the invest in date
depreciation_between_two_dates(Transaction, From_date, To_date, Method, Effective_life_years, Depreciation_value):-
	day_diff(From_date, To_date, Days_difference),
	check_day_difference_validity(Days_difference),
	written_down_value(Transaction, To_date, Method, Effective_life_years, To_date_written_down_value),
	written_down_value(Transaction, From_date, Method, Effective_life_years, From_date_written_down_value),
	Depreciation_value is From_date_written_down_value - To_date_written_down_value.


% Calculates written down value at a certain date equal or posterior to the invest in date using a daily basis
written_down_value(Transaction, Written_down_date, Method, Effective_life_years, Written_down_value):-
	transaction_cost(Transaction, Cost),
	transaction_date(Transaction, Purchase_date),
	transaction_account(Transaction, Account),
	depreciation_between_invest_in_date_and_other_date(
		Cost, 
		Cost, 
		Method,
		Purchase_date, 
		Purchase_date, 
		Written_down_date, 
		Account, 
		1,/* this is in the sense of first year of ownership*/
		Effective_life_years, 
		0,
		Total_depreciation_value
	),
	Written_down_value is Cost - Total_depreciation_value.

% if days difference is less than zero, it means that the requested date 
% in the input value is earlier than the invest in date.
check_day_difference_validity(Days_difference) :-
	(
	Days_difference >= 0
	->
		true
	;
		throw_string('Request date is earlier than the invest in date.')
	).

% Predicates for asserting that the fields of given transactions have particular values
% duplicated from transactions.pl with the difference that transaction_date is used instead of transaction_day
% ok well transactions.pl transactions now use date too, just havent renamed it yet, so we can probably use it 
% The absolute day that the transaction happenned
% ok well transactions.pl uses dates, not days
% input and output xml should use dates too, so idk, best to convert it to days just inside the computation functions and convert it back after
transaction_date(transaction(Date, _, _, _), Date).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account(transaction(_, _, Account_Id, _), Account_Id).
% The amounts by which the account is being debited and credited
transaction_vector(transaction(_, _, _, Vector), Vector).
% Extract the cost of the buy from transaction data
transaction_cost(transaction(_, _, _, t_term(Cost, _)), Cost).


asset_rate(Q, Asset_Type_Label, R) :-
	doc(Q, l:contains, R),
	doc(R, rdf:type, l:depreciation_rate),
	doc(R, l:asset_type_label, Asset_Type_Label),
	!.

asset_rate(_Q, Asset_Type_Label, R) :-
	asset_type_hierarchy_ancestor(Asset_Type_Label, Ancestor_Label),
	doc(R, rdf:type, l:depreciation_rate),
	doc(R, l:asset_type_label, Ancestor_Label),
	!.


asset_type_hierarchy_ancestor(Label, Ancestor_Label) :-
	doc(I, rdf:type, l:depreciation_asset_type_hierarchy_item),
	doc(I, l:child_label, Label),
	doc(I, l:parent_label, Ancestor_Label).

asset_type_hierarchy_ancestor(Label, Ancestor_Label) :-
	doc(I, rdf:type, l:depreciation_asset_type_hierarchy_item),
	doc(I, l:child_label, Label),
	doc(I, l:parent_label, Parent_Label),
	asset_type_hierarchy_ancestor(Parent_Label, Ancestor_Label).





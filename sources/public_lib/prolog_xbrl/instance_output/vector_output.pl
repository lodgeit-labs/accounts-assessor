/*

[r:vec Vec;
r:format text
r:

todo ixbrl vs interactive proof ui

*/
/*
vector is understood to be a list of coords,values

format_vector(Vec,





/*

:model m:accounts [:cash :investments :assets :equity].

:cash a acc:Account.
:investments a acc:Account.
:assets a acc:Account.
:equity a acc:Account.

:cash acc:parent :assets.
:investments acc:parent :assets.


?m 'account relationship formuals' ?f.
?m m:accounts ?accounts.


?accounts 'account relationship formuals2' ?formulas.
?a member ?accounts
?f member ?formulas
	'is for account' ?account;






existence of account implies existence of formula




*/


/* base case */
nil 'account formulas' nil
?accounts 'account formulas' ?formulas
	fr(?accounts, ?af, ?ar)

	/* if account has parent, there is a formula */
	?af parent ?p
	fr(?formulas, ?ff, ?fr)
	?fr 'account formula' ?ff

	/* and recurse */
	?ar 'account formulas' ?fr






nil 'subaccount summation formulas' nil
?accounts 'subaccount summation formulas' ?formulas
	fr(?accounts, ?af, ?ar)
	'account children'(?af, ?children),
	?f op eq
	?f lhs $>'account binder'(account)
	'accounts binders'(?children, ?children_binders)
	?f rhs ?summation_exp
	'summmation exp'(?children_binders ?summation_exp)


'accounts binders'(?accounts, ?binders)
	maplist('account binder', ?accounts, ?binders).

'account binder'(?account, ?binder)
	?binder = [a binder; aspects ([concept account])]

'summation exp'(?items ?summation_exp) :-
	not(?items rest _),
	?items first ?item
	?summation_exp = ?item

'summation exp'(?items ?summation_exp) :-
	fr(items, if, ir),
	fr(?summation_exp, ?sf ?sr)
	summation_exp
		a exp
		op ops:add
		lhs if
		rhs ?sr

at this point we have a formula for each childful account:
[	a formula
	op eq
	lhs [binder for account]
	rhs [a exp; lhs [binder for first account]; rhs [a exp...
]


?model 'model formulas instances' ?instances

% each formula can have multiple instances
'formula instances'
	'bindings of binder to facts'(?lhs, ?lhs_facts)




'bindings of binder to facts'

'binding of binder to fact'
	we will simplify this for now: if a binder has same concept as fact, its a bind















----


reconcilliation of xbrl and our system wrt:
	our adjustment units:
		possibly this could be represented in a xbrl taxonomy, ie, "Assets" is not a single fact-point, or rather, it is a calculated fact, made up of 'assets in report currency' + ..





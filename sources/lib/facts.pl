/*
mock_request :-
	doc_init.
*/
make_fact(Vec, Aspects, Uri) :-
	doc_new_uri(fact, Uri),
	doc_add(Uri, rdf:type, l:fact),
	doc_add(Uri, l:vec, $>flatten([Vec])),
	doc_add(Uri, l:aspects, Aspects).

make_fact(Vec, Aspects) :-
	make_fact(Vec, Aspects, _).

fact_vec(Uri, X) :-
	doc(Uri, l:vec, X).



/*
find all facts with matching aspects
for a fact to match, it has to have all the aspects present in Aspects, and they have to unify.
rest of aspects of the fact are ignored. All matching facts are returned. findall, unifications
are not preserved.
*/
 facts_by_aspects(aspects(Aspects), Facts) :-
	findall(
		Uri,
		(
			doc(Uri, rdf:type, l:fact),
			doc(Uri, l:aspects, aspects(Aspects2)),
			maplist(rebmem(Aspects2), Aspects)
		),
		Facts).



/*
given account role, get balance from corresponding report_entry, and assert a fact (with given aspects)
*/

 add_fact_by_account_role(Json_reports, aspects(Aspects)) :-
	!member(report - Report_path, Aspects),
	path_get_dict(Report_path, Json_reports, Report),
	!member(account_role - Role, Aspects),
	!report_entry_vec_by_role(Report, Role, Vec),
	!account_normal_side($>abrlt(Role), Side),
	maplist(!coord_normal_side_value2(Side), Vec, Values),
	!make_fact(Values, aspects(Aspects), _).

%add_sum_fact_from_report_entries_by_roles(Bs, Roles, New_fact_aspects) :-
%	!maplist(report_entry_vec_by_role(Bs), Roles, Vecs),
%	!vec_sum(Vecs, Sum),
%	!make_fact(Sum, New_fact_aspects, _).



/*
input: 2d matrix of aspect terms and other stuff.
extend aspect terms with additional aspect
*/

add_aspect_to_table(Aspect, In, Out) :-
	!maplist(add_aspect_to_row(Aspect), In, Out).
add_aspect_to_row(Aspect, In, Out) :-
	!maplist(tbl_add_aspect(Aspect), In, Out).
tbl_add_aspect(_, X, X) :-
	X \= aspects(_).
tbl_add_aspect(Aspect, aspects(Aspects), aspects(Aspects2)) :-
	append(Aspects, [Aspect], Aspects2).



/*
input: 2d matrix of aspect terms and other stuff.
replace aspect terms with strings
*/

evaluate_fact_table(Pres, Tbl) :-
	maplist(evaluate_fact_table3, Pres, Tbl).

evaluate_fact_table3(Row_in, Row_out) :-
	maplist(evaluate_fact, Row_in, Row_out).

evaluate_fact(X, X) :-
	X \= aspects(_).

evaluate_fact(In, with_metadata(Values,In)) :-
	evaluate_fact2(In, Values).

/*
this relies on there being no intermediate facts asserted.
*/
evaluate_fact2(In,Sum) :-
	In = aspects(_),
	facts_by_aspects(In, Facts),
	/*(	Facts \= []
	->	true
	;	throw_string(['fact missing:', In])),*/
	facts_vec_sum(Facts, Sum).

facts_vec_sum(Facts, Sum) :-
	maplist(fact_vec, Facts, Vecs),
	vec_sum(Vecs, Sum).





add_summation_fact(Summed_aspectses, Sum_aspectses) :-
	maplist(!facts_by_aspects, Summed_aspectses, Factses),
	flatten(Factses, Facts),
	!facts_vec_sum(Facts, Vec),
	!make_fact(Vec, Sum_aspectses).






 optionally_assert_doc_value_as_unit_fact(Default_currency, Unit, Item, Prop) :-
	(	assert_doc_value_as_unit_fact(Item, Prop, Default_currency, Unit, Prop)
	->	true
	;	true).

 assert_doc_value_as_unit_fact(Default_currency, Unit, Item, Prop) :-
	assert_doc_value_as_unit_fact_with_concept(Default_currency, Unit, Item, Prop, Prop).

 assert_doc_value_as_unit_fact_with_concept(Default_currency, Unit, Item, Prop, Concept) :-
	assert_doc_value_as_fact(Item, Prop, Default_currency,
		aspects([
			concept - Concept,
			unit - Unit
	])).

 assert_doc_value_as_fact(Item, Prop, Default_currency, Aspects) :-
	read_value_from_doc_string(Item, Prop, Default_currency, Value),
	!make_fact(Value, Aspects).




/*

first class formulas:

	"Accounting Equation"
		assets - liabilities = equity

	smsf:
		'Benefits Accrued as a Result of Operations before Income Tax' = 'P&L' + 'Writeback Of Deferred Tax' + 'Income Tax Expenses'

	there is a choice between dealing with (normal-side) values vs dr/cr coords. A lot of what we need to express are not naturally coords, and dealing with them as coords would be confusing. Otoh, translating gl account coords to normal side values can make things confusing too, as seen above.

	'Benefits Accrued as a Result of Operations before Income Tax' = 'P&L', excluding: 'Writeback Of Deferred Tax', 'Income Tax Expenses'



*/

/*

a subset of these declarations could be translated into a proper xbrl taxonomy.

value_formula(equals(
	aspects([concept - smsf/income_tax/'Benefits Accrued as a Result of Operations before Income Tax']),
	aspects([
		report - pl/current,
		account_role - 'ComprehensiveIncome']))),

value_formula(x_is_sum_of_y(
	aspects([concept - smsf/income_tax/'total subtractions from PL']),
	[
		aspects([
			report - pl/current,
			account_role - 'Distribution Received'])
		aspects([
			report - pl/current,
			account_role - 'TradingAccounts/Capital GainLoss']),
		aspects([
			report - pl/current,
			account_role - 'Distribution Received']),
		aspects([
			report - pl/current,
			account_role - 'Contribution Received'])
	])).
*/
/*
	evaluate expressions:
		aspecses with report and account_role aspects are taken from reports. They are forced into a single value. This allows us to do clp on it without pyco. Previously unseen facts are asserted.

*/

/*
% Sr - structured reports
evaluate_value_formulas(Sr) :-
	findall(F, value_formula(F), Fs),
	evaluate_value_formulas(Sr, Fs).

evaluate_value_formulas(Sr, [F|Rest]) :-
	evaluate_value_formula(Sr, F),
	evaluate_value_formulas(Sr, Rest).

evaluate_value_formula(Sr, equals(X, Y)) :-
	evaluate_value(X, Xv)



evaluate_value(X, Xv) :-




asserted:
	aspects([concept - smsf/income_tax/'total subtractions from PL']),
equals(X,aspects([
	concept - smsf/income_tax/'total subtractions from PL'
	memeber - xxx
]),



xbrl:
	fact:
		concept
		context:
			period
			dimension1
*/
/*

fact1:
concept - contribution
taxation - taxable
phase - preserved
fact2:
concept - contribution
taxation - tax-free
phase - preserved
effect - addition

get(concept - contribution):
		get exact match
	or
		get the set of subdividing aspects:
			taxation, phase, effect
		pick first aspect present in all asserted facts
		get([concept - contribution, taxation - _]):
			get the set of subdividing aspects:
				phase, effect
			pick first aspect present in all asserted facts
			get([concept - contribution, taxation - _]):
*/

/*

open problems:
	unreliability of clp - run a sicstus clp service?
	vectors for fact values - would require pyco to solve
*/




computed_unit_fact(Unit, Exp) :-
	exp_concept_to_aspects(Exp, Aspects_exp),
	exp_add_aspect(Aspects_exp, unit - Unit, Aspects_exp_with_aspect_added),
	exp_compute(Aspects_exp_with_aspect_added).

concept_to_aspects(Concept, Aspects) :-
	Aspects = aspects([concept - Concept]).

walk_exp(Func, Exp, Exp2) :-
	Func(Exp, Exp2),
	!.

walk_exp(Func, Exp, Exp2) :-
	Exp =.. [Functor | Args],
	maplist(walk_exp(Func), Args, Args2),
	Exp2 =.. [Functor | Args2],
	!.

exp_concept_to_aspects(Exp, Aspects) :-
	walk_exp(concept_to_aspects, Exp, Aspects).

exp_add_aspect(Aspects_exp, Added, Aspects_exp_with_aspect_added) :-
	walk_exp(add_aspect(Added), Aspects_exp, Aspects_exp_with_aspect_added).

exp_compute(A = B) :-
	assertion(A = aspects(_)),
	exp_eval(B, B2),
	assertion(facts_by_aspects(A, [])),
	!make_fact(B2, A).

exp_eval(X, X2) :-
	X = aspects(_),
	evaluate_fact2(X,X2).

exp_eval(A + B, C) :-
	exp_eval(A, A2),
	exp_eval(B, B2),
	vec_add(A, B, C).

exp_eval(A - B, C) :-
	exp_eval(A, A2),
	exp_eval(B, B2),
	vec_sub(A, B, C).

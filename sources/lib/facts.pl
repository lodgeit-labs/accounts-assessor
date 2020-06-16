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
		Facts
	).



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
/* add aspect if this is an aspects([..]) term, otherwise return it as it is */
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
	(	assert_doc_value_as_unit_fact(Default_currency, Unit, Item, Prop)
	->	true
	;	true).

 assert_doc_value_as_unit_fact(Default_currency, Unit, Item, Prop) :-
	assert_doc_value_as_unit_fact_with_concept(Default_currency, Unit, Item, Prop, Prop).

 assert_doc_value_as_unit_fact_with_concept(Default_currency, Unit, Item, Prop, Concept) :-
	assert_doc_value_as_fact(Item, Prop, Default_currency,
		aspects([
			concept - ($>rdf_global_id(Concept)),
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
	(	atom(Concept)
	;	Concept = _:_),
	Aspects = aspects([concept - ($>rdf_global_id(Concept))]).

walk_exp(Func, Exp, Exp2) :-
	call(Func, Exp, Exp2),
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
	facts_by_aspects(A, Already_asserted),
	(	Already_asserted = []
	->	true
	;	throw_string('internal error')),
	!make_fact(B2, A).

exp_eval(X, X2) :-
	X = aspects(_),
	evaluate_fact2(X,X2).

exp_eval(A + B, C) :-
	exp_eval(A, A2),
	exp_eval(B, B2),
	vec_add(A2, B2, C).

exp_eval(A - B, C) :-
	exp_eval(A, A2),
	exp_eval(B, B2),
	vec_sub(A2, B2, C).

add_aspect(Added, aspects(X), aspects(Y)) :-
	append(X, [Added], Y).







/*
xbrl notes
https://www.xbrl.org/guidance/xbrl-formula-rules-tutorial/#fn:assertions
https://www.xbrl.org/guidance/xbrl-glossary/#taxonomy-defined-dimension



 the test expression will be evaluated for each occurrence of a fact using the concept "Revenue". This may include facts reported with different periods, units or taxonomy-defined dimensions. The characteristics (concept, period, unit, taxonomy-defined dimension and entity) used to uniquely identify a fact are known as "Aspects".



Built-in dimension
    Dimensions that are defined by the XBRL specification, and which are required for all facts (depending on their datatype). For example, the "period" built-in dimension defines the date or period in time to which a fact relates, and the "unit" built-in dimension defines the units, such as a monetary currency, in which a numeric fact is reported. Taxonomies may add additional dimensions, referred to as taxonomy-defined dimensions.


Which of "segment" or "scenario" should be used as the dimension container?
For historical reasons, XBRL provides two alternative containers in which XBRL dimensions can be included, known as "segment" and "scenario". These container elements pre-dates the introduction of XBRL Dimensions, and the split is now redundant.
The choice of which to use is arbitrary, as it does not affect the semantic meaning of the dimensions.
In the absence of other factors, it is suggested that the scenario element is used.



Calculation tree
    Relationships between concepts in a taxonomy for the purpose of describing and validating simple totals and subtotals. [At a technical level, these relationships are defined using the summation-item arcrole in the XBRL specification]



Concept
    A taxonomy element that provides the meaning for a fact. For example, "Profit", "Turnover", and "Assets" would be typical concepts. [approximate technical term: concept (XBRL v2.1) or primary item (XBRL Dimensions)




Cube
    A multi-dimensional definition of related data synonymous with a business intelligence or data warehousing "cube". A cube is defined by combining a set of dimensions with a set of concepts. Cubes are often referred to as "hypercubes", as unlike a physical, 3-dimensional cube, a hypercube may have any number of dimensions. [Approximate technical term: "hypercube". Cube here is used to mean the combination of hypercubes in a single base set]


Data point
    Definition of an item that can be reported in an XBRL report. In technical terms, this is the combination a concept and a number of dimension values. A value may be reported against a data point to give a fact.


Dimension
    A qualifying characteristic that is used to uniquely define a data point. For example, a fact reporting revenue may be qualified by a "geography" dimension, to indicate the region to which the revenue relates. A dimension may be either a taxonomy-defined dimension or a built-in dimension. [Technical term: "Aspect"]


Dimension value
    A value taken by a particular dimension when defining a data point. For example, the dimension value for the period built-in dimension would be a specific date or date range, the dimension value for an explicit taxonomy-defined dimension is a dimension member and the dimension value for a typed taxonomy-defined dimension is a value that is valid against the format that has been specified in the taxonomy.



Fact
    A fact is an individual piece of information in an XBRL report. A fact is represented by reporting a value against a concept (e.g., profit, assets), and associating it with a number of dimension values (e.g., units, entity, period, other dimensions) that together uniquely define a data point.






---




iXBRL report
    A single document that combines structured, computer-readable data with the preparer's presentation using the iXBRL (or Inline XBRL) standard. An iXBRL report provides the same XBRL data as an XBRL report, but embeds it into an HTML document that can be viewed in a web browser. By linking structured data and human-readable presentation into a single document, iXBRL provides the benefits of computer-readable structured data whilst enabling preparers to retain full control over the presentation of their reports.

Label
    A human readable description of a taxonomy component. XBRL labels can be defined in multiple languages and can be of multiple types, such as a "standard label", which provides a concise name for the component, or a "documentation label" which provides a more complete definition of the component.

Preparer's presentation
    The human-readable presentation of a business report. The term is used to refer to the report as it would be presented on paper, PDF or HTML.
    This term is of particular relevance in open reporting environments, where preparers typically have significant control over the layout and presentation of a report. An iXBRL report embeds XBRL data into an HTML document, allowing a single document to provide both the preparer's presentation and structured data from an XBRL report.

Presentation tree
    The organisation of taxonomy elements into a hierarchical structure with the aim of providing a means of visualising or navigating the taxonomy. [At a technical level, the presentation tree is defined using the parent-child arcrole in the XBRL specification]

Open reporting
    An environment where a preparer must make their own decisions about exactly which data points are to be reported. This is commonly found in financial reporting where the reporting requirements are expressed as a set of principles that must be followed, rather than a specific set of data points that must be reported. Open reporting environments may allow preparers to provide an extension taxonomy that defines any additional data points needed, although there are other approaches to implementing open reporting with XBRL.

Closed reporting
    A reporting system in which the set of data points that is to be reported is prescribed completely by the collector of the reports. The process to be followed by a preparer in a closed reporting system is analogous to completing a paper form, as the boxes that may be completed are prescribed completely by the creator of the form (although as with paper forms, closed reporting systems may include specific points of flexibility, such as where rows in a table may be repeated as many times as required).

Table structure
    A view of a taxonomy or report that is designed to replicate tables for presentation or data entry purposes. Table structures are typically used to cope with the complex, dimensional reports often seen in prudential reporting. [At a technical level, the table structure is defined using the Table Linkbase specification]



*/

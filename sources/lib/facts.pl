/*
mock_request :-
	doc_init.
*/
make_fact(Vec, Aspects, Uri) :-
	!doc_new_uri(fact, Uri),
	!doc_add(Uri, rdf:type, l:fact),
	!doc_add(Uri, l:vec, $>flatten([Vec])),
	!doc_add(Uri, l:aspects, Aspects).

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
	!make_fact(Value, Aspects, Uri),
	!doc_add(Uri, l:source, $>doc(Item, Prop)).




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

concept_to_aspects(X, X) :-
	(number(X),!);(rational(X),!).

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
	!exp_eval(B, B2),
	!facts_by_aspects(A, Already_asserted),
	(	Already_asserted = []
	->	true
	;	throw_string('internal error')),
	!make_fact(B2, A).

exp_eval(X, X) :-
	is_list(X). % a vector

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

exp_eval(A * B, C) :-
	exp_eval(A, A2),
	((rational(B),!);(number(B),!)),
	{B2 = B * 100},
	split_vector_by_percent(A2, B2, C, _).

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


(United States Dollars) for monetary values or “meters” for length. The units are expressed as a list of
numerator units with an optional list of denominator units. This allows for compound units, such as
dollars/share or miles/hour. It also allows for units such as meters 2 by specifying multiple “meter” units in
the numerator.


Other types of concepts may be used as organizational containers for concept core dimensions that are
semantically related. These are called grouping concepts, and they define structures within a taxonomy,
such as an XBRL table structure or a domain of possible values.


This new XBRL dimension is defined by a concept that represents the nature of an axis in the
data set. In the example, a concept named Person would be added to the taxonomy. Good practice would
also dictate that a suffix is appended to the name of this concept to indicate that this is a taxonomy-
defined dimension and should not itself be used as a concept core dimension. In other words, this new
concept should not be used directly with any one fact. For more information on suffixes, see the XBRL
Style Guide. This would make the final concept name PersonAxis.


Now that there is a concept to describe the taxonomy-defined dimension, the components, or members,
of this dimension must be described. In the example, this would be Jared and Allyson, the two people
who belong to the reporting entity, “Bob’s Household.” They therefore belong to the new PersonAxis.
XBRL offers numerous ways to express these components, but for this example, concepts named Jared
and Allyson will be used. Again, good style practice and clarity suggest adding a suffix to these concept
names to indicate they should not be used as concept core dimensions. Thus, they will be named
JaredMember and AllysonMember. For a more in-depth discussion on the other options to express the
components of a taxonomy-defined dimension, see Section 3.4.2.


Facts with a numeric data type must have a decimals or precision property that states how
mathematically precise the value of the fact is. Because all numeric facts must have precision, XBRL
software can maintain precision when performing mathematical calculations. Given this, when comparing
a computed value versus a fact value, XBRL software can automatically accommodate for rounding
errors.


For example, an XBRL date must be in ISO 8601 format but many
textual dates are written in descriptive language. An XBRL transformation describes how the descriptive
language can be converted to the appropriate format. For a list of rules and more information, see the
XBRL Transformation Registry.


Inline XBRL also offers a scaling property on individual facts, to indicate to XBRL software that the value
of the fact must be scaled before it is interpreted. For example, a table of facts may be expressed in
millions without the trailing zeros to aid in human readability but Inline XBRL has appropriate scaling so
the value of 123 is interpreted as 123000000.

Naming conventions should be employed
following certain style rules (check the XBRL US Style Guide for language and reference styles). Of note
in this case is the use of specific suffixes to indicate a concept’s role.

Concepts that do not actually intersect facts often have their
abstract property set to “true.” This specifically indicates that a concept is not a concept core dimension
but rather an organizational item.

Reporting data for “Income (Loss)” may be a
situation where a negative fact represents that loss, but that fact may be presented as positive for a
specific human-readable presentation. This would be accomplished with a negated label.

Within the XBRL definition, the closed property of the hypercube specifies that all taxonomy-defined
dimensions in this hypercube must intersect on a fact in order for that fact to be part of this hypercube. If
a taxonomy-defined dimension is omitted, the default value for that dimension is assumed to intersect on
the fact. If there is no default value, that taxonomy-defined dimension cannot intersect, which will prevent
the hypercube from including the fact. An open hypercube removes this constraint. In the widget example,
each fact must have the taxonomy-defined dimensions CustomerNameAxis, WidgetTypeAxis, and
OrderDateAxis intersecting upon it. For an explicit taxonomy-defined dimension, a dimension-default
arcrole allows for a concept to be the default value of the dimension, meaning facts that do not explicitly
intersect with that taxonomy-defined dimension are implied to intersect with the default value when
rendering the hypercube. If facts do not intersect with a concept member of the taxonomy-defined
dimension and that dimension has a dimension-default set, those facts will be considered to intersect with
the dimension-default. The dimension-default is usually set to the domain concept, which implies that
facts that do not intersect the dimension are a total of that dimension.




VARIABLES



Every XBRL variable implies an XPath expression. A variable is evaluated by evaluating the implied XPath in the context of an XBRL instance.

The XPath expressions implied by variables are evaluated using the <xbrli:xbrl> element of the input XBRL instance as the context item.

 For various reasons, the XBRL Specification [XBRL 2.1] makes minimal use of the normal hierarchical structure of XML, instead requiring relatively flat syntax for XBRL instances and for their supporting XML schemas and linkbases.

This design makes it cumbersome to use XPath or XQuery to select data from XBRL instances based on their content and their supporting discoverable taxonomy sets, at least without a library of custom functions.

This specification provides a framework for an alternative syntax for specifying the filters that are to be applied to an XBRL instance to select the required data from them, if it is available. The alternative syntax is extensible in the sense that additional filters can be defined as they are deemed useful.

For two facts, an aspect test can be used to test whether an aspect is not reported for both facts or is reported with an equivalent value for both facts.

Two facts are aspect-matched facts if they have exactly the same aspects and, for each of aspect that they both have, the value for that aspect matches for the two facts.

All formulae have a default accuracy rule. A formula MAY also have an accuracy rule specified by either a <formula:precision> child element or a <formula:decimals> child element on the formula.

An aspect rule is a rule for determining the value of an output aspect. Rules for determining the output concept, the output context and the output units of measurement (for numeric facts), are all different types of aspect rules.


http://www.xbrl.org/WGN/xf-grammar/WGN-2018-10-10/xf-grammar-WGN-2018-10-10.html

1.1 Example XF rule
namespace eg = "http://www.example.com/ns" ;
assertion RevenueNonNegative {
    unsatisfied-message (en) "Revenue must not be negative";
    variable $revenue {
        concept-name eg:Revenue ;
    };
    test { $revenue ge 0 };
};

http://www.xbrl.org/specification/dimensions/rec-2012-01-25/dimensions-rec-2006-09-18+corrected-errata-2012-01-25-clean.html

http://www.xbrl.org/WGN/dimensions-use/WGN-2015-03-25/dimensions-use-WGN-2015-03-25.html

https://www.xbrl.org/Specification/extensible-enumerations-2.0/REC-2020-02-12/extensible-enumerations-2.0-REC-2020-02-12.html

https://www.xbrl.org/REQ/calculation-requirements-2.0/REQ-2019-02-06/calculation-requirements-2.0-2019-02-06.html

XBRL 2.1 summation-item relationships have defined validation behaviour, with conformant processors being required to signal an "inconsistency" if the facts in an XBRL report do not conform to the prescribed relationships. The validation behaviour does not include any provision for inferring values which are not explicitly reported.

XBRL 2.1 summation-item relationships are restricted to describing summation relationships between numeric facts which are c-equal, that is, which share the same period, dimensions and other contextual information, among other restrictive conditions.


XBRL formula linkbase <-> XF language
https://github.com/Arelle/Arelle/blob/master/arelle/plugin/formulaSaver.py
https://github.com/Arelle/Arelle/blob/master/arelle/plugin/formulaLoader.py
now, what's the semantic model of XF and what's the semantic model of XULE?

namespace cdp-og = "http://www.cdp.net/xbrl/cdp/og/2016-08-30/";
assertion-set assertionSet {
assertion valueAssertion {
unsatisfied-message (en) "Emissions intensities (Scope1 + Scope 2) associated with current production
and operations, Year ending must be between 2010 and 2016. ";
variable $OperationsYearEnding {
nils
fallback {0}
concept-name cdp-og:EmissionsIntensitiesScope1Scope2ProductionOperationsYearEnding;
typed-dimension cdp-og:EmissionsIntensitiesScope1Scope2ProductionOperationsAxis;
};
test {fn:number(fn:string($OperationsYearEnding)) >= 2010 and
fn:number(fn:string($OperationsYearEnding)) <= 2016};
};
};


XULE, from “XBRL rule,” was created by XBRL.US to provide a way to query and check XBRL reports by validating business rules prior to filing.

The goal behind XULE was to create a modern alternative to XBRL Formula

The primary purpose of XULE is to provide a user friendly syntax to query and manipulate XBRL data. Unlike XBRL Formula, XULE does not have the ability to create facts or define new XBRL reports. XULE has been primarily used to validate SEC filings as part of the DQC rules. The DQC rules are published in a XULE format.

XULE is also used to query XBRL taxonomies and render them as open API schemas, or as iXBRL forms.

XULE is syntax independent and will operate on XBRL reports published in JSON, iXBRL, CSV and XML formats. The language operates on an XBRL data model and ignores the XBRL syntax. For example, XULE does not allow a user to query all the XML contexts in an XBRL report in an XML format.

In addition to its XULE processor and validator, XMLSpy includes the industry’s first XULE editor.

https://xbrl.us/xule/?doing_wp_cron=1593455136.4135539531707763671875

@concept = RevenueFromContractWithCustomerExcludingAssessedTax @ProductOrServiceAxis = IPhoneMember

The detailed options available within factset filtering are defined in detail in the XULE guide and the XULE examples page.

also supported in arelle: https://github.com/DataQualityCommittee/dqc_us_rules/releases




2 Segment and scenario

The XBRL v2.1 specification provided two containers for providing additional information about the nature of a reported fact: the <segment> and <scenario> elements contained within the context. Both of these containers can contain arbitrary XML content, with the XBRL v2.1 specification providing no mechanism for defining or constraining the information that appears within these elements.

The XBRL Dimensions specification provides a more structured way to define additional information about the nature of a reported fact. This is preferrable to using arbitrary XML elements within segment and scenario, as the meaning of XBRL Dimensions can be precisely defined and constrained using an XBRL taxonomy.

The syntactic constructs which appear in an XBRL instance document to represent such dimensional qualifications may appear within either the <segment> or <scenario> elements, depending on the definition of the relevant hypercube.

As the meaning of an XBRL Dimension can be defined precisely and completely within an XBRL taxonomy, separately grouping them into the broad categories of "segment" and "scenario" offers little additional value. As the decision as to whether an individual dimension appears within <segment> or <scenario> is attached to the hypercube as a whole rather than to individual dimensions, attempting to classify dimensions between the two introduces additional complexity as additional hypercubes must be introduced.

Common practice in taxonomy design is to select one or other out of the two options, and to use it for all hypercubes within a taxonomy. The choice between segment and scenario is arbitrary: in effect, the greater precision of dimension definition offered by the XBRL Dimensions specification renders the broad, binary classification offered by the XBRL v2.1 specification redundant from a technical perspective.


2.1 Recommendations
    The <segment> and <scenario> elements should only be used to contain XBRL Dimensions, and should not be used to contain other XML elements (this will be enforced where a <segment> or <scenario> element is constrained by a closed hypercube)
    A taxonomy should use one or other of <segment> and <scenario> for its hypercubes exclusively.
    In the absence of reasons to do otherwise (for example, compatibility with other taxonomies or consistency with prior versions), it is suggested that new taxonomies define hypercubes for use on <scenario> only.
    The container that is not used for dimensions should be empty. It is recommended that this is enforced by external validation rather than taxonomy constructs.



Dimensional Taxonomies Requirements
Aggregator
	A dimension member that represents the result of summing facts about other members of the same dimension.
Example: In the products dimension, the member “TotalProducts” is the aggregator of all possible products.
Measure
	A measure is an XBRL fact whose context contains dimensions.


Instance authors must be able to create contexts with Dimensions. Taxonomy authors must be able to define the valid combinations of Dimensions that may or must occur in the contexts of the facts of any concept.  Instances with facts or contexts violating the validity constraints are invalid.

Example: A taxonomy requires that the context of every Sales fact must have a product and region dimension and may have others.
Example: A taxonomy requires that the context of every Asset fact must have a region dimension but no other dimensions.


https://docs.oracle.com/en/cloud/saas/enterprise-performance-reporting-cloud/udepr/about_dimensions_172x8e51bd9a.html


The semantic attributes describe the meaning of the arc's ending resource relative to its starting resource. The arcrole attribute corresponds to the [RDF] notion of a property, where the role can be interpreted as stating that "starting-resource HAS arc-role ending-resource." This contextual role can differ from the meaning of an ending resource when taken outside the context of this particular arc. For example, a resource might generically represent a "person," but in the context of a particular arc it might have the role of "mother" and in the context of a different arc it might have the role of "daughter."


"Although xlink: role describes the resource, xlink: arcrole defines how they relate"
"The attribute role describes the meaning of the resource. "
 http://zvon.org/xxl/xlink/xlink_extend/OutputExamples/xml6_out.xml.html

"XML is almost always misused"
 https://www.devever.net/~hl/xml





.......

https://www.xbrl.org/guidance/esd-main/

*/

/*




----


reconcilliation of xbrl and our system wrt:
	our adjustment units:
		possibly this could be represented in a xbrl taxonomy, ie, "Assets" is not a single fact-point, or rather, it is a calculated fact, made up of 'assets in report currency' + ..



*/
/*

https://www.swi-prolog.org/pldoc/doc/_SWI_/library/xpath.pl?show=src
"inspired"
xpath3 is a strict superset of xpath2.




Match an element in a DOM structure. The syntax is inspired by XPath, using () rather than [] to select inside an element. First we can construct paths using / and //:

//Term
    Select any node in the DOM matching term.
/Term
    Match the root against Term.
Term
    Select the immediate children of the root matching Term.






A schema document may include other schema documents for the same namespace, and may import schema documents for a different namespace.




element(









*/

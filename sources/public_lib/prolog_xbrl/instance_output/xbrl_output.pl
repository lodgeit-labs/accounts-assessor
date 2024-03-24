
:- record section(context, header, entries, footer).

 'create XBRL instance'(Xbrl, Static_Data, Start_Date, End_Date, Report_Currency, Balance_Sheet, ProfitAndLoss, Trial_Balance) :-
 
	Fact_Sections = [
		section(Instant_Context_Id_Base, '\n<!-- balance sheet: -->\n', Balance_Sheet, ''),
		section(Duration_Context_Id_Base, '\n<!-- profit and loss: -->\n', ProfitAndLoss, ''),
		section(Instant_Context_Id_Base, '\n<!-- trial balance: -->\n', Trial_Balance, '')
	],
	!xbrl(Xbrl, Children),
	!add(Children, [Units_Xml, Contexts_Xml, Dimensional_Facts,Facts]),
	Entity_Identifier = element(identifier, [scheme="http://www.example.com"],['TestData']),
	!build_base_contexts(Start_Date, End_Date, Entity_Identifier, Instant_Context_Id_Base, Duration_Context_Id_Base, Contexts0),
	!fact_lines(Report_Currency, Fact_Sections, Facts),
	!maybe_print_dimensional_facts(
		Static_Data.put([
			entity_identifier=Entity_Identifier,
			instant_context_id_base=Instant_Context_Id_Base,
			duration_context_id_base=Duration_Context_Id_Base
		]), Contexts0, Contexts1, Dimensional_Facts
	),
	!print_used_units(Units_Xml),
	!print_contexts(Contexts1, Contexts_Xml).


 fact_lines(_, [], []).

 fact_lines(Report_Currency, [Section|Sections], [Lines_H|Lines_T]) :-
	Lines_H = [Fact_Lines],
	/*section_header(Section, Header),
	section_footer(Section, Footer),*/
	!section_context(Section, Context),
	!section_entries(Section, Entries),
	!format_report_entries(xbrl, 0, 0, Report_Currency,
		Context, Entries, Fact_Lines),
	!fact_lines(Report_Currency, Sections, Lines_T).

 build_base_contexts(Start_Date, End_Date, Entity_Identifier, Instant_Context_Id_Base, Duration_Context_Id_Base, Base_Contexts) :-
	Entity = entity(Entity_Identifier, ''),
	/* build up two basic non-dimensional contexts used for simple xbrl facts */
	date(Context_Id_Year,_,_) = End_Date,
	context_id_base('I', Context_Id_Year, Instant_Context_Id_Base),
	context_id_base('D', Context_Id_Year, Duration_Context_Id_Base),
	Base_Contexts = [
		context(Instant_Context_Id_Base, End_Date, Entity, ''),
		context(Duration_Context_Id_Base, (Start_Date, End_Date), Entity, '')
	].

 print_used_units(Elements) :-
	result(R),
	findall(
		Element,
		(
			*doc(R, l:used_unit, Unit, xml),
			(print_used_unit(Unit, Element) -> true ; throw('internal error 3'))
		),
		Elements).

 print_used_unit(Unit, Element) :-
	sane_unit_id(Unit, Id_Attr),
	sane_id(Unit, Sane),
	format(string(Measure), "iso4217:~w", [Sane]),
	Element = element(
		'xbrli:unit',
		['id'=Id_Attr],
		[element('xbrli:measure', [], [Measure])]
	).

 xbrl(
	element('xbrli:xbrl', [
		'xmlns:xbrli'="http://www.xbrl.org/2003/instance",
		'xmlns:link'="http://www.xbrl.org/2003/linkbase",
		'xmlns:xlink'="http://www.w3.org/1999/xlink",
		'xmlns:xsi'="http://www.w3.org/2001/XMLSchema-instance",
		'xmlns:iso4217'="http://www.xbrl.org/2003/iso4217",
		'xmlns:basic'="http://www.xbrlsite.com/basic",
		'xmlns:xbrldi'="http://xbrl.org/2006/xbrldi",
		'xsi:schemaLocation'=Schema_Location],
		Children),Children)
:-
	result_property(l:taxonomy_url_base, Base),
	atomics_to_string([Base,'basic.xsd'], Basic),
	atomics_to_string([Base,'basic-formulas.xml'], Formulas),
	atomics_to_string([Base,'basic-formulas-cross-checks.xml'], Formulas_Crosschecks),
	atomics_to_string([
		'http://www.xbrlsite.com/basic',
		Basic,
		'http://www.xbrl.org/2003/instance',
		'http://www.xbrl.org/2003/xbrl-instance-2003-12-31.xsd',
		 'http://www.xbrl.org/2003/linkbase',
		  'http://www.xbrl.org/2003/xbrl-linkbase-2003-12-31.xsd',
		   'http://xbrl.org/2006/xbrldi',
		    'http://www.xbrl.org/2006/xbrldi-2006.xsd'], ' ', Schema_Location),
	maplist(add(Children), [
		element('link:schemaRef', [
				'xlink:type'="simple",
				'xlink:href'=Basic,
				'xlink:title'="Taxonomy schema"], []),
		element('link:linkbaseRef', [
				'xlink:type'="simple",
				'xlink:href'=Formulas,
				'xlink:arcrole'="http://www.w3.org/1999/xlink/properties/linkbase"], []),
		element('link:linkBaseRef', [
			 	'xlink:type'="simple",
			 	'xlink:href'=Formulas_Crosschecks,
				'xlink:arcrole'="http://www.w3.org/1999/xlink/properties/linkbase"], [])
		]).

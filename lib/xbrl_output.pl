:- module(_, [create_instance/10]).

:- use_module('detail_accounts').
:- use_module('xbrl_contexts', [
		print_contexts/1,
		context_id_base/3
]).
:- use_module('fact_output').


:- use_module(library(xbrl/structured_xml)).
:- use_module(library(record)).


:- record section(context, header, entries, footer).

create_instance(Xbrl, Static_Data, Start_Date, End_Date, Accounts, Report_Currency, Balance_Sheet, ProfitAndLoss, ProfitAndLoss2_Historical, Trial_Balance) :-
	Fact_Sections = [
		section(Instant_Context_Id_Base, '\n<!-- balance sheet: -->\n', Balance_Sheet, ''),
		section(Duration_Context_Id_Base, '\n<!-- profit and loss: -->\n', ProfitAndLoss, ''),
		section(Duration_Context_Id_Base, '\n<!-- historical profit and loss (fixme wrong context id): \n', ProfitAndLoss2_Historical, '\n-->\n'),
		section(Instant_Context_Id_Base, '\n<!-- trial balance: -->\n', Trial_Balance, '')
	],
	xbrl(Xbrl, [Facts, Dimensional_Facts, Units_Xml, Contexts_Xml]),
	Entity_Identifier = '<identifier scheme="http://www.example.com">TestData</identifier>',
	build_base_contexts(Start_Date, End_Date, Entity_Identifier, Instant_Context_Id_Base, Duration_Context_Id_Base, Contexts0),
	fact_lines(Accounts, Report_Currency, Fact_Sections, Facts, [], Units0),


	maybe_print_dimensional_facts(
		Static_Data.put([
			entity_identifier=Entity_Identifier,
			instant_context_id_base=Instant_Context_Id_Base,
			duration_context_id_base=Duration_Context_Id_Base
		]), Contexts0, Contexts1, Units0, Units1, Dimensional_Facts
	),
	maplist(print_used_unit, Units1, Units_Xml),
	print_contexts(Contexts1, Contexts_Xml).

fact_lines(_, _, [], [], Units_In, Units_In).

fact_lines(Accounts, Report_Currency, [Section|Sections], [Lines_H|Lines_T], Units_In, Units_Out) :-
	Lines_H = [Header, Fact_Lines, Footer],
	section_header(Section, Header),
	section_footer(Section, Footer),
	section_context(Section, Context),
	section_entries(Section, Entries),
	fact_output:format_report_entries(xbrl, 0, Accounts, 0, Report_Currency, 
		Context, Entries, Units_In, Units_Mid, [], Fact_Lines),
	fact_lines(Accounts, Report_Currency, Sections, Lines_T, Units_Mid, Units_Out).

maybe_print_dimensional_facts(Static_Data,Contexts_In, Contexts_Out, Units_In, Units_Out, Xml) :-
	(	Static_Data.output_dimensional_facts = on
	->	print_dimensional_facts(Static_Data, (Contexts_In, Units_In), (Contexts_Out, Units_Out), Xml)
	;
		(
			Contexts_In = Contexts_Out, 
			Units_In = Units_Out, 
			Xml = comment('dimensional facts off')
		)
	).

print_dimensional_facts(Static_Data, Results0, Results3, [Xml1, Xml2, Xml3]) :-
 	dict_vars(Static_Data, [Instant_Context_Id_Base, Duration_Context_Id_Base]),
	detail_accounts:print_banks(Static_Data, Instant_Context_Id_Base, Results0, Results1, Xml1),
	detail_accounts:print_forex(Static_Data, Duration_Context_Id_Base, Results1, Results2, Xml1),
	detail_accounts:print_trading(Static_Data, Results2, Results3, Xml1).

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
	
print_used_unit(unit_id(Unit, Id), [comment(Unit_Str), Element]) :-
	term_string(Unit, Unit_Str),
	format(string(Id_Attr), "U-~w", [Id]),
	format(string(Measure), "iso4217:~w", [Id]),
	Element = element('xbrli:unit',
		['id'=sanitize_id(Id_Attr)],
		[element('xbrli:measure', [], Measure)).

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
	doc:request_has_property(l:taxonomy_url_base, Base),
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
	maplist(utils:add(Children), [
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

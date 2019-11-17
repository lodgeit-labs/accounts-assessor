:- module(_, []).

create_instance(Static_Data, Taxonomy_Url_Base, Start_Date, End_Date, Accounts, Report_Currency, Balance_Sheet, ProfitAndLoss, ProfitAndLoss2_Historical, Trial_Balance) :-
	xbrl_output:print_header(Taxonomy_Url_Base),
	Entity_Identifier = '<identifier scheme="http://www.example.com">TestData</identifier>',
	xbrl_output:build_base_contexts(Start_Date, End_Date, Entity_Identifier, Instant_Context_Id_Base, Duration_Context_Id_Base, Base_Contexts),
	
	

	Fact_Sections = [section()],
	format_report_entries(xbrl, Accounts, 0, Report_Currency, 
		Instant_Context_Id_Base, Balance_Sheet, [], Units0, [], Bs_Lines),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, 
		Duration_Context_Id_Base, ProfitAndLoss,  Units0, Units1, [], Pl_Lines),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, 
		Duration_Context_Id_Base, ProfitAndLoss2_Historical,  Units1, Units2, [], Pl_Historical_Lines),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, 
		Instant_Context_Id_Base, Trial_Balance, Units2, Units_Out, [], Tb_Lines),

	maplist(fact_lines(Accounts, Report_Currency), Fact_Sections, Report_Lines_List)

	atomic_list_concat(Report_Lines_List, Fact_Lines).



	(
		Static_Data.output_dimensional_facts = on
	->
		print_dimensional_facts(Static_Data, Instant_Context_Id_Base, Duration_Context_Id_Base, Entity_Identifier, (Base_Contexts, Units0, []), (Contexts3, Units4, Dimensions_Lines))
	;
		(
			Contexts3 = Base_Contexts, 
			Units4 = Units0, 
			Dimensions_Lines = ['<!-- off -->\n']
		)
	),
	maplist(write_used_unit, Units4), nl, nl,
	print_contexts(Contexts3), nl, nl,
	writeln('<!-- dimensional facts: -->'),
	maplist(write, Dimensions_Lines),
	writeln(Fact_Lines),
	xbrl_output:print_footer.

(header, footer, context, entries)

fact_lines(Accounts, Report_Currency, [Section|Sections], [Lines_Out|Lines_Tail], Units_In, Units_Out) :-
	Lines_Out = [Header, Fact_Lines, Footer],
	section_header(Section, Header),
	section_footer(Section, Footer),
	section_context(Section, Context),
	section_entries(Section, Entries),




/* global data of the xbrl-instance-outputting operation */
new_global_data_handle(H),
rdf_assert(op, format, xbrl),
Max_Detail_Level





	format_report_entries(xbrl, Accounts, 0, Report_Currency, 
		Context, Entries, Units_In, Units_Mid, [], Fact_Lines),

	flatten([
		'\n<!-- balance sheet: -->\n', Bs_Lines, 
		'\n<!-- profit and loss: -->\n', Pl_Lines,
		'\n<!-- historical profit and loss (fixme wrong context id): \n', Pl_Historical_Lines, '\n-->\n',
		'\n<!-- trial balance: -->\n',  Tb_Lines
	], Report_Lines_List),
	

print_dimensional_facts(Static_Data, Instant_Context_Id_Base, Duration_Context_Id_Base, Entity_Identifier, Results0, Results3) :-
	print_banks(Static_Data, Instant_Context_Id_Base, Entity_Identifier, Results0, Results1),
	print_forex(Static_Data, Duration_Context_Id_Base, Entity_Identifier, Results1, Results2),
	print_trading(Static_Data, Results2, Results3).


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
	
write_used_unit(Unit) :-
	format('  <xbrli:unit id="U-~w"><xbrli:measure>iso4217:~w</xbrli:measure></xbrli:unit>\n', [Unit, Unit]).



print_header(Taxonomy_Url_Base) :-
	write('<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" xmlns:link="http://www.xbrl.org/2003/linkbase" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:iso4217="http://www.xbrl.org/2003/iso4217" xmlns:basic="http://www.xbrlsite.com/basic" xmlns:xbrldi="http://xbrl.org/2006/xbrldi" xsi:schemaLocation="http://www.xbrlsite.com/basic '),
	write(Taxonomy_Url_Base),writeln('basic.xsd http://www.xbrl.org/2003/instance http://www.xbrl.org/2003/xbrl-instance-2003-12-31.xsd http://www.xbrl.org/2003/linkbase http://www.xbrl.org/2003/xbrl-linkbase-2003-12-31.xsd http://xbrl.org/2006/xbrldi http://www.xbrl.org/2006/xbrldi-2006.xsd">'),
	write('  <link:schemaRef xlink:type="simple" xlink:href="'), write(Taxonomy_Url_Base), writeln('basic.xsd" xlink:title="Taxonomy schema" />'),
	write('  <link:linkbaseRef xlink:type="simple" xlink:href="'), write(Taxonomy_Url_Base), writeln('basic-formulas.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
	write('  <link:linkBaseRef xlink:type="simple" xlink:href="'), write(Taxonomy_Url_Base), writeln('basic-formulas-cross-checks.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
	nl.
 
print_footer :-
	writeln('</xbrli:xbrl>').

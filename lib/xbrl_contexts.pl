
/*
some record types to streamline output of xbrl contexts. No relation to the stuff in xbrl/ (yet)
*/
:- use_module(library(record)).

:- record entity(identifier, segment).
:- record dimension_reference(id, element_name).
:- record dimension_value(reference, value).
:- record context(id, period, entity).

	
print_contexts(Contexts) :-
	maplist(print_context, Contexts).

print_context(context(Id, Period, Entity)) :-
	write('<context id="'), write(Id), writeln('">'),
	print_period(Period),
	print_entity(Entity),
	writeln('</context>').

print_period((Start, End)) :-
	format_date(Start, Start_Str),
	format_date(End, End_Str),
	writeln('\t<period>'),
	write('\t\t<startDate>'), write(Start_Str),	writeln('</startDate>'),
	write('\t\t<endDate>'), write(End_Str),	writeln('</endDate>'),
	writeln('\t</period>').

print_period(Date) :-
	format_date(Date, Date_Str),
	writeln('\t<period>'),
	write('\t\t<instant>'), 
	write(Date_Str),
	writeln('</instant>'),
	writeln('\t</period>').
	
print_entity(entity(Identifier, Segment)) :-
    writeln('\t<entity>'),
    write('\t\t'),
    writeln(Identifier),
    print_segment(Segment),
    writeln('\t</entity>').
    
print_segment('').

print_segment(segment([dimension_value(dimension_reference(Id, Element_Name), Value)])) :-
	writeln('\t\t<segment>'),
	write('\t\t\t<xbrldi:typedMember dimension="'), write(Id), writeln('">'),
    write('\t\t\t<'), write(Element_Name), write('>'), write(Value), write('</'), write(Element_Name), writeln('>'), 
	writeln('\t\t\t</xbrldi:typedMember>'),
	writeln('\t\t</segment>').



context_id_base(Period_Type, Year, Base) :-
	atomic_list_concat([Period_Type, '-', Year], Base).


/* context's id is expected to be unbound, it is passed in by Context_Id,
and will be modified, if required, to be unique */
ensure_context_exists(Contexts_In, Context, Suggested_Context_Id, Contexts_Out) :-
	(
		member(Context, Contexts_In)
	->
		true
	;
		add_context(Contexts_In, Suggested_Context_Id, Context, Contexts_Out)
	).

add_context(Contexts_In, Context_Id, Context, Contexts_Out) :-
	context_id(Context1, Context_Id),
	(
		member(Context1, Contexts_In)
	->
		(
			atomic_list_concat([Context_Id, '_2'], Context_Id2),
			add_context(Contexts_In, Context_Id2, Context, Contexts_Out)
		)
	;
		(
			Context1 = Context,
			append(Contexts_In, [Context], Contexts_Out)
		)
	).

:- record context_arg0(context_id_base, context_template, period_type, fact_name, dimension_id, dimension_element_id).

get_context_id(Account, Context_Info, Contexts_In, Contexts_Out, Context_Id) :-
	Context_Info = context_arg0(Context_Id_Base, Context_Template, Period_Type, _Fact_Id, Dimension_Id_Base, Dimension_Element_Id),
	(
		Period_Type = duration
	->
		Period_Suffix = '_Duration'
	;
		Period_Suffix = '_Instant'
	),
	copy_term(Context_Template, Context),
	atomic_list_concat([Dimension_Id_Base, Period_Suffix], Dimension_Id),
	atomic_list_concat([Dimension_Element_Id, Period_Suffix], Element_Id),
	Context = context(_, _, entity(_, segment([
		dimension_value(
			dimension_reference(Dimension_Id, Element_Id),
			Account
	)]))),
	atomic_list_concat([Context_Id_Base, '-', Account], Suggested_Context_Id),
	ensure_context_exists(Contexts_In, Context, Suggested_Context_Id, Contexts_Out),
	context_id(Context, Context_Id).


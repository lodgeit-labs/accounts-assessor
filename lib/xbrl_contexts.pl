:- module(xbrl_contexts, [
		print_contexts/1,
		context_id_base/3,
		ensure_context_exists/6,
		context_arg0_period/2
]).

:- use_module(days, [format_date/2]).
:- use_module(library(record)).

/*
some record types to streamline output of xbrl contexts. No relation to the stuff in xbrl/
*/
:- record entity(identifier, segment).
:- record dimension_reference(id, element_name).
:- record dimension_value(reference, value).
:- record context(id, period, entity, scenario).
:- record context_arg0(id_base, period, entity, scenario).

/*

*/
ensure_context_exists(Short_Id, Value, Context_Info, Contexts_In, Contexts_Out, Id) :-
	Context_Info = context_arg0(Id_Base, Period, Entity_In, Scenario_In),
	Entity_In = entity(Entity_Identifier, Segment_In),
	Context = context(Id, Period, Entity, Scenario),
	Entity = entity(Entity_Identifier, Segment),
	update_dimension_value(Segment_In, Period, Value, Segment),
	update_dimension_value(Scenario_In, Period, Value, Scenario),
	atomic_list_concat([Id_Base, '-', Short_Id], Suggested_Context_Id),
	find_or_add_context(Contexts_In, Context, Suggested_Context_Id, Contexts_Out).
	%context_id(Context, I),
	%writeln(('so:',I)).

	
update_dimension_value('', _, _, '').
update_dimension_value(In, Period, Value, Out) :-
	In = [Point_In],
	Out = [Point_Out],
	update_point(Point_In, Period, Value, Point_Out).

/*
	add period suffix based on period type, and bind Value
*/
update_point(Point_In, Period, Value, Point_Out) :-
	Point_In = dimension_value(
		dimension_reference(Dimension_Id_Base, Element_Id_Base),
		_
	),
	Point_Out = dimension_value(
		dimension_reference(Dimension_Id, Element_Id),
		Value
	),
	(
		Period = (_,_)
	->
		Period_Suffix = '_Duration'
	;
		Period_Suffix = '_Instant'
	),

	atomic_list_concat([Dimension_Id_Base, Period_Suffix], Dimension_Id),
	atomic_list_concat([Element_Id_Base, Period_Suffix], Element_Id).

/* context's id is expected to be unbound, it is passed in by Context_Id,
and will be modified, if required, to be unique */
find_or_add_context(Contexts_In, Context, Suggested_Context_Id, Contexts_Out) :-
	assertion(ground(Contexts_In)),
	%writeln(('in:', Contexts_In)),
	%writeln(('want:', Suggested_Context_Id)),
	(
		member(Context, Contexts_In)
	->
		(
			%writeln(('found:',Context)),
			Contexts_Out = Contexts_In
		)
	;
		(
			add_context(Contexts_In, Suggested_Context_Id, Context, Contexts_Out)
			%writeln(('added:', Context))
		)
	).

add_context(Contexts_In, Suggested_Context_Id, Context, Contexts_Out) :-
	context_id(Context1, Suggested_Context_Id),
	(
		member(Context1, Contexts_In)
	->
		(
			atomic_list_concat([Suggested_Context_Id, '_2'], Suggested_Context_Id2),
			add_context(Contexts_In, Suggested_Context_Id2, Context, Contexts_Out)
		)
	;
		(
			Context1 = Context,
			append(Contexts_In, [Context], Contexts_Out)
		)
	).

context_id_base(Period_Type, Year, Base) :-
	atomic_list_concat([Period_Type, '-', Year], Base).

	
print_contexts(Contexts) :-
	maplist(print_context, Contexts).

print_context(Context) :-
	print_context2(Context).
	
print_context2(context(Id, Period, Entity, Scenario)) :-
	write('<xbrli:context id="'), write(Id), writeln('">'),
	print_period(Period),
	print_entity(Entity),
	print_scenario(Scenario),
	writeln('</xbrli:context>').

print_period((Start, End)) :-
	format_date(Start, Start_Str),
	format_date(End, End_Str),
	writeln('\t<xbrli:period>'),
	write('\t\t<xbrli:startDate>'), write(Start_Str),	writeln('</xbrli:startDate>'),
	write('\t\t<xbrli:endDate>'), write(End_Str),	writeln('</xbrli:endDate>'),
	writeln('\t</xbrli:period>'),!.

print_period(Date) :-
	format_date(Date, Date_Str),
	writeln('\t<xbrli:period>'),
	write('\t\t<xbrli:instant>'), 
	write(Date_Str),
	writeln('</xbrli:instant>'),
	writeln('\t</xbrli:period>').
	
print_entity(entity(Identifier, Segment)) :-
    writeln('\t<xbrli:entity>'),
    write('\t\t'),
    writeln(Identifier),
    print_segment(Segment),
    writeln('\t</xbrli:entity>').
    
print_segment('').

print_segment([dimension_value(dimension_reference(Id, Element_Name), Value)]) :-
	writeln('\t\t<xbrli:segment>'),
	write('\t\t\t<xbrldi:typedMember dimension="'), write(Id), writeln('">'),
    write('\t\t\t<'), write(Element_Name), write('>'), write(Value), write('</'), write(Element_Name), writeln('>'), 
	writeln('\t\t\t</xbrldi:typedMember>'),
	writeln('\t\t</xbrli:segment>').

print_scenario('').

print_scenario([dimension_value(dimension_reference(Id, Element_Name), Value)]) :-
	writeln('\t\t<xbrli:scenario>'),
	write('\t\t\t<xbrldi:typedMember dimension="'), write(Id), writeln('">'),
    write('\t\t\t<'), write(Element_Name), write('>'), write(Value), write('</'), write(Element_Name), writeln('>'), 
	writeln('\t\t\t</xbrldi:typedMember>'),
	writeln('\t\t</xbrli:scenario>').

/*
With our Ledger solution, we want to be able to have a consolidated entity where the various entities that make up the consolidated entity have their own aspects - i.e. instead of Geo Area Aspect, have Sub Entity Aspect
*/

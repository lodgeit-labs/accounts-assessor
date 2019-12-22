:- module(_, []).

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

	
print_contexts(Contexts, Xml) :-
	maplist(print_context, Contexts, Xml).

print_context(
	context(Id, Period, Entity, Scenario),
	element('xbrli:context', [id=sane_id(Id)], [Xml1, Xml2, Xml3]))
:-
	print_period(Period,Xml1),
	print_entity(Entity,Xml2),
	print_scenario(Scenario,Xml3).

print_period(
	(Start, End),
	element('xbrli:period', [], [
		element('xbrli:startDate', [], [Start_Str]),
		element('xbrli:endDate', [], [End_Str])]))
:-
	format_date(Start, Start_Str),
	format_date(End, End_Str),
	!.

print_period(
	Date,
	element('xbrli:period', [], [
		element('xbrli:instant', [], [Date_Str])]))
:-
	format_date(Date, Date_Str).

print_entity(
	entity(Identifier, Segment),
	element('xbrli:entity', [], [Identifier, Segment_Xml]))
:-
    print_segment(Segment, Segment_Xml).

print_segment(X, Y) :-
	print_segment_or_scenario('xbrli:segment', X, Y).
print_scenario(X, Y) :-
	print_segment_or_scenario('xbrli:scenario', X, Y).

print_segment_or_scenario(_, '', []).

print_segment_or_scenario(
	Segment_Or_Scenario,
	[dimension_value(dimension_reference(Id, Element_Name), Value)],
	element(Segment_Or_Scenario, [], [
		element('xbrldi:typedMember', [dimension=sane_id(Id)], [
			element(Element_Name, [], [Value])])])).

/*
With our Ledger solution, we want to be able to have a consolidated entity where the various entities that make up the consolidated entity have their own aspects - i.e. instead of Geo Area Aspect, have Sub Entity Aspect
*/

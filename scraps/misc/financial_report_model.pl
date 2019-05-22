% An Aspect describes a Fact

% The core aspect types are reporting_entity, calendar_period, and concept
aspect_type(aspect(Type, _), Type).
% Information necessary to uniquely describe a fact
aspect_description(aspect(_, Description), Description).

% A Fact defines a single, observable, reportable piece of information contained within a Report

% A list of aspects to contextualize this fact
fact_aspects(fact(Aspects, _, _, _, _), Aspects).
% Every fact has exactly one fact value
fact_value(fact(_, Value, _, _, _), Value).
% Numeric fact values have the properties of Units
fact_unit(fact(_, _, Unit, _, _), Unit).
% Numeric fact values have the properties of Rounding
fact_rounding(fact(_, _, _, Rounding, _), Rounding).
% A Fact may have zero to many Parenthetical Explanations
fact_explanations(fact(_, _, _, _, Explanations), Explanations).

% A Fact Set has an Information Model

% ...
info_label(info(Label, _, _, _, _, _), Label).
% ...
info_report_element_class(info(_, Report_Element_Class, _, _, _, _), Report_Element_Class).
% ...
info_period_type(info(_, _, Period_Type, _, _, _), Period_Type).
% ...
info_balance(info(_, _, _, Balance, _, _), Balance).
% ...
info_name(info(_, _, _, _, Name, _), Name).
% The name of the parent information model entry
info_member_of(info(_, _, _, _, _, Member_Of), Member_Of).

% Predicate asserts that there is an aspect with type Aspect_Type and with description
% Aspect_Description in Aspects.

aspect_member(Aspects, Aspect_Type, Aspect_Description) :-
	member(Aspect, Aspects),
	aspect_type(Aspect, Aspect_Type),
	aspect_description(Aspect, Aspect_Description).

% Removes the aspects of the types specified in the list Removal_Aspect_Types from
% Aspect_Set1 to give Aspect_Set2.

remove_aspect_types(Removal_Aspect_Types, Aspect_Set1, Aspect_Set2) :-
	findall(Aspect,
		(member(Aspect, Aspect_Set1),
			aspect_type(Aspect, Aspect_Type),
			\+ member(Aspect_Type, Removal_Aspect_Types)),
		Aspect_Set2).

% Asserts that Aspect_Set1 and Aspect_Set2 are permutations of each other after having
% removed Modulo_Aspect_Types from both of them.

equal_modulo(Modulo_Aspect_Types, Aspect_Set1, Aspect_Set2) :-
	remove_aspect_types(Modulo_Aspect_Types, Aspect_Set1, Aspect_Set1_Reduced),
	remove_aspect_types(Modulo_Aspect_Types, Aspect_Set2, Aspect_Set2_Reduced),
	permutation(Aspect_Set1_Reduced, Aspect_Set2_Reduced).

% Asserts that Member_Names_Set is the set of names of the concepts that are members of
% the concept with the name Aspect_Name.

member_names(Info_Model, Aspect_Name, Member_Names_Set) :-
	findall(Member_Name,
		(member(Member_Info, Info_Model),
			info_member_of(Member_Info, Aspect_Name),
			info_name(Member_Info, Member_Name)),
		Member_Names),
	list_to_set(Member_Names, Member_Names_Set).

% Asserts that the fact Member_Fact is a fact whose concept aspect is a member of the
% concept aspect of Fact, and that Member_Fact's aspect are the same as Fact's aspect
% modulo the concept aspect.

member_fact(Fact_Set, Info_Model, Fact, Member_Fact) :-
	fact_aspects(Fact, Aspects),
	aspect_member(Aspects, concept, Description),
	member_names(Info_Model, Description, Names),
	member(Member_Fact, Fact_Set),
	fact_aspects(Member_Fact, Member_Fact_Aspects),
	aspect_member(Member_Fact_Aspects, concept, Member_Fact_Concept),
	member(Member_Fact_Concept, Names),
	equal_modulo([concept], Aspects, Member_Fact_Aspects).

% Asserts that the sum of the fact values of the member facts of Fact is equal to
% Whole_Value.

fact_total_value(Fact_Set, Info_Model, Fact, Whole_Value) :-
	findall(Value,
		(member_fact(Fact_Set, Info_Model, Fact, Member_Fact),
			fact_value(Member_Fact, Value)),
		Values),
	sum_list(Values, Whole_Value).

% Asserts that the sum of the fact values of the member facts of Fact is equal to the fact
% value of Fact.

value_equals_total(Fact_Set, Info_Model, Fact) :-
	fact_total_value(Fact_Set, Info_Model, Fact, Value),
	fact_value(Fact, Value).

% Asserts that Aspect_Fact is the same fact as Fact but with its aspects updated to
% New_Aspects.

update_fact_aspects(New_Aspects, Fact, Aspect_Fact) :-
	fact_aspects(Aspect_Fact, New_Aspects),
	fact_value(Fact, Value), fact_value(Aspect_Fact, Value),
	fact_unit(Fact, Unit), fact_unit(Aspect_Fact, Unit),
	fact_rounding(Fact, Rounding), fact_rounding(Aspect_Fact, Rounding),
	fact_explanations(Fact, Explanations), fact_explanations(Aspect_Fact, Explanations).
	
% Asserts that Table_Row is a row of Fact_Set, by which it is meant that it is a table
% of all the facts associated with the given aspect Aspect.

table_row(Aspect, Aspect_Types, Fact_Set, Table_Row) :-
	aspect_type(Aspect, Aspect_Type),
	findall(Aspect_Fact,
		(member(Fact, Fact_Set),
			fact_aspects(Fact, Aspects),
			member(Aspect, Aspects),
			remove_aspect_types([Aspect_Type], Aspects, New_Aspects),
			update_fact_aspects(New_Aspects, Fact, Aspect_Fact)),
		Aspect_Facts),
	table(Aspect_Types, Aspect_Facts, Table_Row).

% Asserts that the last argument is a table of the Fact_Set where each row is a table
% containing facts associated with just one aspect of the aspects supplied in the first
% argument.

table_rows([], _, _, []).

table_rows([Aspect | Aspects], Aspect_Types, Fact_Set, [(Aspect, Row_Table) | Row_Tl]) :-
	table_row(Aspect, Aspect_Types, Fact_Set, Row_Table),
	table_rows(Aspects, Aspect_Types, Fact_Set, Row_Tl).

% Asserts that Table is a table of the Fact_Set where the top-most headings are possible
% descriptions of the first aspect_type of the first argument.

table([], Fact_Set, Fact_Set).

table([Aspect_Type | Aspect_Types], Fact_Set, Table) :-
	findall(Aspect,
		(member(Fact, Fact_Set),
			fact_aspects(Fact, Aspects),
			member(Aspect, Aspects),
			aspect_type(Aspect, Aspect_Type)),
		Aspects),
	list_to_set(Aspects, Aspects_Set),
	table_rows(Aspects_Set, Aspect_Types, Fact_Set, Table).

% Rules guide, control, suggest, or influence behavior.

% ...
rule_label(rule(Label, _, _, _, _), Label).
% ...
rule_report_element_class(rule(_, Report_Element_Class, _, _, _), Report_Element_Class).
% ...
rule_weight(rule(_, _, Weight, _, _), Weight).
% ...
rule_balance(rule(_, _, _, Balance, _), Balance).
% ...
rule_name(rule(_, _, _, _, Name), Name).


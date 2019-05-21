element_id(element(Id, _), Id).
element_name(element(_, Name), Name).

% Although each taxonomy defines a single set of elements representing a set of business
% reporting Concepts, the human-readable XBRL documentation for those concepts, including
% labels (strings used as human-readable names for each concept) and other explanatory
% documentation, is contained in a resource element in the label Linkbase. The resource
% uses the @xml:lang attribute to specify the language used (via the XML standard lang
% attribute) and an optional classification of the purpose of the documentation (via a
% role attribute).

label_arc_role(label_arc(Role, _, _), Role).
label_arc_from(label_arc(_, From, _), From).
label_arc_to(label_arc(_, _, To), To).

label_label(label(Label, _, _), Label).
label_role(label(_, Role, _), Role).
label_content(label(_, _, Content), Content).

% Presentation links are used to arrange taxonomy elements into a hierarchy and specific
% ordering. In general, different uses will require different sets of presentation links.
% There is one set of users - taxonomy developers and domain experts working with a
% taxonomy - whose presentation needs remain relevant throughout the entire lifecycle of a
% taxonomy. In some sense this view is "context free" as opposed to the presentation of
% instance data that is "context dependent." When taxonomies are published they cannot
% contain all possible presentations but they MAY contain at least one "developer's eye"
% view, which is "context free" in the sense that it does not need to take XBRL Instance
% contexts into account. The presentation Linkbase in this example could contain
% presentation links to organise Concepts to look like line items in a financial
% statement. Another presentation linkbase could contain links to organise a subset of
% these same concepts into a data collection form.

presentation_arc_role(presentation_arc(Role, _, _), Role).
presentation_arc_from(presentation_arc(_, From, _), From).
presentation_arc_to(presentation_arc(_, _, To), To).

% This specification is an extension to the XBRL Specification [XBRL 2.1]. It defines
% syntax for declaration of two kinds of variables: fact variables that only evaluate to
% sequences of facts in an XBRL instance and general variables that can evaluate to a
% broader range of values. This specification also defines syntax for parameters that can
% be given default values or values that are supplied by processing software. 

fact_variable_label(fact_variable(Label), Label).

variable_filter_arc_role(variable_filter_arc(Role, _, _), Role).
variable_filter_arc_from(variable_filter_arc(_, From, _), From).
variable_filter_arc_to(variable_filter_arc(_, _, To), To).

%  When evaluating the variables in a variable-set, XPath variable references with this
% QName are references to the variable or parameter. Note that, for parameters, this QName
% MAY differ from the QName given in the parameter declaration. 

variable_arc_role(variable_arc(Role, _, _, _), Role).
variable_arc_from(variable_arc(_, From, _, _), From).
variable_arc_to(variable_arc(_, _, To, _), To).
variable_arc_name(variable_arc(_, _, _, Name), Name).

concept_name_label(concept_name(Label, _), Label).
concept_name_content(concept_name(_, Content), Content).

% This specification is an extension to the XBRL Validation specification [VALIDATION]. It
% defines XML syntax [XML] for assertions that test the values of the variables of each
% evaluation of a given variable set. It is a construct similar to that of a formula
% resource, but its output is a boolean value instead of a complete XBRL fact. The Boolean
% value is obtained by evaluating the an XPath expression that is specified as part of the
% assertion. 

value_assertion_label(value_assertion(Label, _, _), Label).
value_assertion_id(value_assertion(_, Id, _), Id).
value_assertion_test(value_assertion(_, _, Test), Test).

instance_element(instance(Element, _, _), Element).
instance_context_ref(instance(_, Context_Ref, _), Context_Ref).
instance_content(instance(_, _, Content), Content).

% The <context> element contains information about the Entity being described, the
% reporting Period and the reporting scenario, all of which are necessary for
% understanding a business fact captured as an XBRL item.

context_id(context(Id, _, _), Id).
context_explicit_members(context(_, Explicit_Members, _), Explicit_Members).
context_period(context(_, _, Period), Period).

explicit_member_dimension(explicit_member(Dimension, _), Dimension).
explicit_member_content(explicit_member(_, Content), Content).

% The following code gets all the information associated with a particular context as
% an association list called Point.

point(Instances, Context, Point) :-
  context_id(Context, Context_Id),
  context_explicit_members(Context, Explicit_Members),
  % Each explicit member is going to be a coordinate of this point
  findall(Coord,
    (member(Explicit_Member, Explicit_Members),
    explicit_member_dimension(Explicit_Member, Dimension),
    explicit_member_content(Explicit_Member, Content),
    Coord = (Dimension, Content)), Coords_A),
  % Each instance element with this context is going to be a coordinate of this point
  findall(Coord,
    (member(Instance, Instances),
      instance_context_ref(Instance, Context_Id),
      instance_element(Instance, Element),
      instance_content(Instance, Content),
      Coord = (Element, Content)), Coords_B),
  % This point comprises all its coordinate information
  append(Coords_A, Coords_B, Point).

% Renders the given point using a schema and presentation and label linkbases to control
% how the rendering is done.

render(Point, Elements, Label_Arcs, Labels, Presentation_Arcs, Concept, Rendering) :-
  % Use a label arc to get from the concept to the label
  member(Label_Arc, Label_Arcs),
  label_arc_from(Label_Arc, Concept),
  label_arc_to(Label_Arc, L_To),
  label_arc_role(Label_Arc, 'concept-label'),
  % Use a label to get from the label to the string value
  member(Label, Labels),
  label_label(Label, L_To),
  label_role(Label, 'label'),
  label_content(Label, L_Content),
  % Use an element to get from an id to a name
  member(Element, Elements),
  element_id(Element, Concept),
  element_name(Element, Name),
  % Use the point to get from a name to values
  findall(Value, member((Name, Value), Point), Values),
  % Recurse on all the child concepts
  findall(Sub_Rendering,
    (member(Presentation_Arc, Presentation_Arcs),
      presentation_arc_role(Presentation_Arc, 'parent-child'),
      presentation_arc_from(Presentation_Arc, Concept),
      presentation_arc_to(Presentation_Arc, Sub_Concept),
      render(Point, Elements, Label_Arcs, Labels, Presentation_Arcs, Sub_Concept, Sub_Rendering)),
    Sub_Renderings),
  % Rendering comprises label, values, and sub-renderings
  Rendering = (L_Content, Values, Sub_Renderings).

% Asserts that Concept is a root concept with respect to the presentation arcs. That is,
% there will be arcs coming from Concept, but none going to Concept.

root(Presentation_Arcs, Concept) :-
  % Concept must be the parent of something
  member(Presentation_Arc_A, Presentation_Arcs),
  presentation_arc_role(Presentation_Arc_A, 'parent-child'),
  presentation_arc_from(Presentation_Arc_A, Concept),
  % Concept must not be the child of anything
  forall((member(Presentation_Arc_B, Presentation_Arcs),
  presentation_arc_role(Presentation_Arc_B, 'parent-child')),
  \+ presentation_arc_to(Presentation_Arc_B, Concept)).

% The following code displays an instance using a schema and presentation and label
% linkbases to control how the rendering is done.

display(Instances, Contexts, Elements, Presentation_Arcs, Label_Arcs, Labels, Display) :-
  % Get a context
  member(Context, Contexts),
  % Get the point of data corresponding to the context
  point(Instances, Context, Point),
  % Get a root concept with respect to parent-child arcs
  root(Presentation_Arcs, Concept),
  % Render the the point using the given root concept
  render(Point, Elements, Label_Arcs, Labels, Presentation_Arcs, Concept, Display).

% Takes the given point of an XBRL instance and makes a binding for each variable
% associated with the variable set that has the label VA_Label.

bindings(Point, VA_Label, Variable_Arcs, Fact_Variables, Variable_Filter_Arcs, Concept_Names, Bindings) :-
  findall(Binding,
    % Use the variable arc to get a variable associated with the variable set
    (member(Variable_Arc, Variable_Arcs),
      variable_arc_role(Variable_Arc, 'variable-set'),
      variable_arc_from(Variable_Arc, VA_Label),
      variable_arc_name(Variable_Arc, Name),
      variable_arc_to(Variable_Arc, VA_To),
      % Ensure that the target of the variable arc is a declared variable
      member(Fact_Variable, Fact_Variables),
      fact_variable_label(Fact_Variable, VA_To),
      % Use the variable filter arc to get to a concept name filter
      member(Variable_Filter_Arc, Variable_Filter_Arcs),
      variable_filter_arc_role(Variable_Filter_Arc, 'variable-filter'),
      variable_filter_arc_from(Variable_Filter_Arc, VA_To),
      variable_filter_arc_to(Variable_Filter_Arc, VFA_To),
      % Get the concept name specified by this filter
      member(Concept_Name, Concept_Names),
      concept_name_label(Concept_Name, VFA_To),
      concept_name_content(Concept_Name, Content),
      % Get the value of the fact with the concept name
      member((Content, Value), Point),
      % Make a binding that ties the name in the variable arc to the aformentioned value
      Binding = (Name, Value)), Bindings).

% Evaluate the given formula to a numerical value using the given bindings. Note that the
% only supported operations are addition, subtraction, multiplication, division, and
% exponentiation.

formula_eval(Formula, Bindings, Value) :-
  atomic(Formula),
  member((Formula, Value), Bindings).

formula_eval(A+B, Bindings, Value) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  Value is A_Value + B_Value.

formula_eval(A-B, Bindings, Value) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  Value is A_Value - B_Value.

formula_eval(A*B, Bindings, Value) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  Value is A_Value * B_Value.

formula_eval(A/B, Bindings, Value) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  Value is A_Value / B_Value.

formula_eval(A^B, Bindings, Value) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  Value is A_Value ^ B_Value.

% Verifies that the given relation holds once the given bindings have been substituted
% in. Note that the only supported relations are not equal, equal, greater than, less
% than, and their various combinations.

verify_relation(A =:= B, Bindings) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  A_Value =:= B_Value.

verify_relation(A < B, Bindings) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  A_Value < B_Value.

verify_relation(A =< B, Bindings) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  A_Value =< B_Value.

verify_relation(A > B, Bindings) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  A_Value > B_Value.

verify_relation(A >= B, Bindings) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  A_Value >= B_Value.

verify_relation(A =\= B, Bindings) :-
  formula_eval(A, Bindings, A_Value),
  formula_eval(B, Bindings, B_Value),
  A_Value =\= B_Value.

% Validates the given value assertion in the given context using the given formula
% linkbase.

validate_assertion_in_context(Value_Assertion, Instances, Context, Variable_Arcs, Fact_Variables, Variable_Filter_Arcs, Concept_Names) :-
  % Get the point of data corresponding to the context
  point(Instances, Context, Point),
  value_assertion_label(Value_Assertion, VA_Label),
  % Get the variable bindings necessary for the evaluation of this assertion
  bindings(Point, VA_Label, Variable_Arcs, Fact_Variables, Variable_Filter_Arcs, Concept_Names, Bindings),
  % Get the actual test of the value assertion
  value_assertion_test(Value_Assertion, Test),
  % Verify that the relation given in the test holds.
  verify_relation(Test, Bindings).

% Validates the given value assertion in all the given contexts using the given formula
% linkbase.

validate_assertion(Value_Assertion, Instances, Contexts, Variable_Arcs, Fact_Variables, Variable_Filter_Arcs, Concept_Names) :-
  forall(member(Context, Contexts),
    validate_assertion_in_context(Value_Assertion, Instances, Context, Variable_Arcs, Fact_Variables, Variable_Filter_Arcs, Concept_Names)).

% Validates all the given value assertions in all the given contexts using the given
% formula linkbase.

validate_assertions(Value_Assertions, Instances, Contexts, Variable_Arcs, Fact_Variables, Variable_Filter_Arcs, Concept_Names) :-
  forall(member(Value_Assertion, Value_Assertions),
    validate_assertion(Value_Assertion, Instances, Contexts, Variable_Arcs, Fact_Variables, Variable_Filter_Arcs, Concept_Names)).


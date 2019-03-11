% An Aspect describes a Fact

% The core aspect types are 'Reporting Entity', 'Calendar Period', and 'Concept'
aspect_type(aspect(Type, _), Type).
% Information necessary to uniquely describe a fact
aspect_description(aspect(_, Description), Description).

% A Fact defines a single, observable, reportable piece of information contained within a Report

% A list of aspects to contextualize this fact
fact_aspects(fact(Aspects, _, _, _), Aspects).
% Every fact has exactly one fact value
fact_value(fact(_, Value, _, _), Value).
% Numeric fact values have the properties of Units
fact_unit(fact(_, _, Unit, _), Unit).
% Numeric fact values have the properties of Rounding
fact_rounding(fact(_, _, _, Rounding), Rounding).

% A Fact Set has an Information Model

% ...
info_label(info(Label, _, _, _, _), Label).
% ...
info_report_element_class(info(_, Report_Element_Class, _, _, _), Report_Element_Class).
% ...
info_period_type(info(_, _, Period_Type, _, _), Period_Type).
% ...
info_balance(info(_, _, _, Balance, _), Balance).
% ...
info_name(info(_, _, _, _, Name), Name).

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

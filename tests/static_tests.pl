:- module(static_tests, []).

:- use_module(library(xsd)).
:- use_module('../lib/files').

:- begin_tests('Static XSD validations').
test(0) :-
	writeln(""),
	writeln('XML: default_action_taxonomy.xml, XSD: bases/ActionTaxonomy.xsd'),
	(
		xsd_validate(my_schemas('bases/ActionTaxonomy.xsd'), my_static('default_action_taxonomy.xml'))
	->
		true
	;
		writeln("ERROR: `default_action_taxonomy.xml` does not satisfy schema `ActionTaxonomy.xsd`"),
		fail
	).
:- end_tests('Static XSD validations').

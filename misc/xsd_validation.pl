:- module(xsd_validation, []).

:- use_module(library(xsd/validate)).
:- use_module(library(xsd/flatten)).
:- use_module(library(sgml)).
:- use_module('../lib/files.pl').
:- use_module('../lib/utils.pl').

:-
	
	load_structure(my_schemas('bases/ActionTaxonomy.xsd'), Schema_DOM, [dialect(xmlns), space(remove), keep_prefix(true)]),
	load_structure(my_static('default_action_taxonomy.xml'), Instance_DOM, [dialect(xmlns), space(remove), keep_prefix(true)]),

	utils:flatten_xml(Schema_DOM, Schema_ID),
	utils:flatten_xml(Instance_DOM, Instance_ID),

	writeln('XML: default_action_taxonomy.xml, XSD: bases/ActionTaxonomy.xsd'),
	(
		validate(Schema_ID, Instance_ID)
	->
		writeln("Success")
	;
		writeln("ERROR: `default_action_taxonomy.xml` does not satisfy schema `ActionTaxonomy.xsd`"),
		fail
	).

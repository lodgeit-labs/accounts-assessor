:- module(xml, [
	validate_xml/2
]).

:- use_module(library(xsd/flatten)).

/*
Like `xml_flatten/2` from library(xsd/flatten) but works on already loaded XML objects instead of filepaths.
*/
flatten_xml(XML, ID) :-
	flatten:root_id(Root_ID),
	flatten:register_file_id(ID),
	flatten:xml_flatten_nodes(ID,Root_ID,0,XML),
	!.

/*
Validates an XML instance against an XSD schema by calling an external Python script
*/
validate_xml(Instance_File, Schema_File) :-
	catch(
		setup_call_cleanup(
			process_create('../python/venv/bin/python3',['../python/src/xmlschema_runner.py',Instance_File,Schema_File],[]),
			true,
			true
		),
		_,
		throw('Input file failed XSD schema validation.')
	).

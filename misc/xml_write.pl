test :-
	load_structure("comments.xml", Request_Dom, [dialect(sgml), keep_prefix(true)]),
	format("~w~n", [Request_Dom]).
	%xml_write(Request_Dom, [])

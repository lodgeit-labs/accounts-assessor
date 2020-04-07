
process_request_hirepurchase_new :-
	fail,
	doc(Q, rdf:type, hp:hp_calculator_query),
	writeq(Q).

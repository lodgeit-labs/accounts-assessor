
process_request_hirepurchase_new :-
	doc(Q, rdf:type, l:hp_calculator_query),
	writeq(Q).

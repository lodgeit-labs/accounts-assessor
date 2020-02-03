:- use_module('../misc/chr_hp').

chase_kb(N) :-
	start(N).

% needs to account for rdf:value representation
doc_to_chr_constraints :-
	findall(
		_,
		(
			doc(S,P,O),
			fact(S,P,O)
		),
		_
	).

doc_from_chr_constraints :-
	extract_chr_facts(Facts),

	add_doc_facts(Facts).

add_doc_facts([]).
add_doc_facts([fact(S,P,O) | Facts]) :-
	doc_add(S,P,O),
	add_doc_facts(Facts).


process_request_hirepurchase_new :-
	doc(l:request, hp_ui:hp_calculator_query, Q),
	doc_to_chr_constraints,
	(
		chase_kb(20)
	->
		doc_from_chr_constraints
	;	fail % inconsistency
	),
	writeq(Q).

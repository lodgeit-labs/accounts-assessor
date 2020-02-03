
chase_kb(N) :-
	start(N).

% needs to convert from rdf:value representation
doc_to_chr_constraints :-
	get_doc_objects(Objects),
	get_doc_lists(Lists),
	findall(
		_,
		(
			doc(S,P,O),
			chr_convert_list_pred(P,New_P),
			(
				member(S, Objects),
				P \= a,
				doc(O, rdf:value, V)
			->	X = V
			;	X = O
			),
			(
				member(X:List_URI, Lists)
			->	fact(S,New_P,List_URI),
				fact(List_URI,first,X)
			;	fact(S,New_P,X)
			)
		),
		_
	).

chr_convert_list_pred(rdf:first,value) :- !.
chr_convert_list_pred(rdf:rest,next) :- !.
chr_convert_list_pred(P, P).

get_doc_objects(Objects) :-
	findall(
		Object,
		(
			doc(Object, a, T),
			T \= list
		),
		Objects
	).

get_doc_lists(Lists) :-
	findall(
		List:List_URI,
		(
			doc(List, a, list),
			doc_new_uri(List_URI)
		),
		Lists
	).

doc_from_chr_constraints :-
	extract_chr_facts(Facts),

	add_doc_facts(Facts).

add_doc_facts([]).
add_doc_facts([fact(S,P,O) | Facts]) :-
	doc_add(S,P,O),
	add_doc_facts(Facts).


process_request_hirepurchase_new :-
	doc(l:request, hp_ui:hp_calculator_query, _),
	doc_to_chr_constraints,
	format(user_error, "doc_to_chr_constraints success~n",[]),
	(
		chase_kb(20)
	->
		doc_from_chr_constraints
	;	fail % inconsistency
	).

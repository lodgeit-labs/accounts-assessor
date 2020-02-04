
chase_kb(N) :-
	format(user_error, "Starting chase(~w)~n", [N]),
	findall(
		Fact,
		'$enumerate_constraints'(Fact),
		Facts
	),
	format("Facts: ~w~n", [Facts]),
	start(N).

doc_to_chr_constraints :-
	get_doc_objects(Objects),
	format("doc_to_chr_constraints:get_doc_objects(~w)~n", [Objects]),
	get_doc_lists(Lists),
	format("doc_to_chr_constraints:get_doc_lists(~w)~n", [Lists]),
	findall(
		fact(S,P,O),
		docm(S,P,O),
		Facts
	),
	convert_facts(Facts, Objects, Lists).

convert_facts([], _, _).
convert_facts([fact(S,P,O) | Facts], Objects, Lists) :-
	format("convert_facts: ~w ~w ~w~n", [S,P,O]),
	chr_convert_atom(P,New_P),
	(
		member(S, Objects),
		New_P \= a,
		docm(O,'http://www.w3.org/1999/02/22-rdf-syntax-ns#value',V)
	->	X = V
	;	X = O
	),
	% currently rdf:nil is being sent as a placeholder
	(
		member(X:List_URI, Lists)
	->	fact(S,New_P,List_URI),
		fact(List_URI,first,X)
	;	fact(S,New_P,X)
	),
	convert_facts(Facts, Objects, Lists).

chr_convert_atom(rdf:first,value) :- !.
chr_convert_atom(rdf:rest,next) :- !.
chr_convert_atom('http://www.w3.org/1999/02/22-rdf-syntax-ns#type',a) :- !.
chr_convert_atom('https://rdf.lodgeit.net.au/v1/calcs/hp#hp_contract',hp_arrangement) :- !.
chr_convert_atom('https://rdf.lodgeit.net.au/v1/calcs/hp#cash_price',cash_price) :- !.
chr_convert_atom('https://rdf.lodgeit.net.au/v1/calcs/hp#interest_rate',interest_rate) :- !.
chr_convert_atom('https://rdf.lodgeit.net.au/v1/calcs/hp#hp_installments',installments) :- !.
chr_convert_atom('https://rdf.lodgeit.net.au/v1/calcs/hp#repayment_amount',repayment_amount) :- !.
chr_convert_atom(P, P).

get_doc_objects(Objects) :-
	findall(
		Object,
		(
			docm(Object, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', T),
			%docm(Object, a, T),
			T \= list
		),
		Objects
	).

get_doc_lists(Lists) :-
	findall(
		List:List_URI,
		(
			docm(List, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', list),
			%docm(List, a, list),
			doc_new_uri(List_URI)
		),
		Lists
	).

doc_from_chr_constraints :-
	extract_chr_facts(Facts),

	add_doc_facts(Facts).

add_doc_facts([]).
add_doc_facts([fact(S,P,O) | Facts]) :-
	(
		\+((
			docm(S1,P1,O1),
			S1 == S,
			P1 == P,
			O1 == O
		))
	-> 	doc_add(S,P,O)
	;	true
	),
	add_doc_facts(Facts).


process_request_hirepurchase_new :-
	format(user_error, "process_request_hirepurchase_new~n", []),
	doc(l:request, hp_ui:hp_calculator_query, _),
	format(user_error, "found hp_ui:hp_calculator_query~n", []),
	doc_to_chr_constraints,
	format(user_error, "doc_to_chr_constraints success~n",[]),
	(
		chase_kb(20)
	->
		doc_from_chr_constraints
	;	fail % inconsistency
	).


:- use_module(library(dcg/basics)).

money_string(value(Unit, Amount)) --> blanks, number(Amount), blanks,  string(Unit0), blanks, {atom_codes(Unit, Unit0)}.
money_string(value(Unit, Amount)) --> blanks, string(Unit0), blanks, number(Amount), blanks, {atom_codes(Unit, Unit0)}.


%:- string_codes("5457.878700 AUD", C), phrase(money_string(X), C), writeq(X).
%:- string_codes("rstrstrst5457.878700", C), phrase(money_string(X), C), writeq(X).


 string_value(S, V) :-
	string_codes(S, C), phrase(money_string(V), C).

 vector_from_string(Default_Unit, Side, S, [V]) :-
	!value_from_string(Default_Unit, S, V0),
	!coord_normal_side_value(V,Side,V0).

 value_from_string(Default_Unit, S, V) :-
	(	(number(S);rational(S))
	->	V = value(Default_Unit, S)
	;	(	number_string(N, S)
		->	V = value(Default_Unit, N)
		;	string_value(S, V))
	).

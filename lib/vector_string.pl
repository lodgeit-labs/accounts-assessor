
:- use_module(library(dcg/basics)).

money_string(value(Unit, Amount)) --> blanks, number(Amount), blanks,  string(Unit0), blanks, {atom_codes(Unit, Unit0)}.
money_string(value(Unit, Amount)) --> blanks, string(Unit0), blanks, number(Amount), blanks, {atom_codes(Unit, Unit0)}.


%:- string_codes("5457.878700 AUD", C), phrase(money_string(X), C), writeq(X).
%:- string_codes("rstrstrst5457.878700", C), phrase(money_string(X), C), writeq(X).


value_string(S, V) :-
	string_codes(S, C), phrase(money_string(V), C).

vector_string(Default_Unit, Side, S, V) :-
	(	number_string(N, S)
	->	V0 = value(Default_Unit, N)
	;	value_string(S, V0)),
	maplist(coord_normal_side_value2(Side), V, [V0]).


:- record coord(unit, debit).
:- record value(unit, amount).




	
% -------------------------------------------------------------------
% Pacioli group operations. These operations operate on vectors. A vector is a list of
% coordinates. A coordinate is a triple comprising a unit, a debit amount, and a credit
% amount. See: On Double-Entry Bookkeeping: The Mathematical Treatment Also see: Tutorial
% on multiple currency accounting

% The identity for vector addition.

vec_identity([]).

% Computes the (additive) inverse of a given vector.
% - returns a vector of coordinates with debit and credit values switched around

vec_inverse(As, Bs) :-
	maplist(coord_inverse, As, Bs).

coord_inverse(coord(Unit, A_Debit), coord(Unit, A_Credit)) :- {A_Credit = -A_Debit}.
coord_inverse(value(Unit, Value), value(Unit, Value_Inverted)) :- {Value_Inverted = -Value}.

% Each coordinate of a vector can be replaced by other coordinates that equivalent for the
% purposes of the computations carried out in this program. This predicate reduces the
% coordinates of a vector into a canonical form.
%  - returns vector with same coordinates, just minimized by substracting a common value from
%    debit and credit, so that one of them becomes 0, for example 150,50 -> 100,0.
% if both debit and credit is 0, the coord is removed.

/* fixme: rename to vec_reduce_coords, because this reduces individual coords to normal form, but not against each other.
define vec_reduce(X) as vec_add(X, [])? */

vec_reduce(As, Bs) :-
	vec_reduce2(As, Result_Raw),
	exclude(is_zero_coord, Result_Raw, Result_Nonzeroes), 
	maplist(unify_coords_or_values, Bs, Result_Nonzeroes),
	!/*is the cut needed?*/.

vec_reduce2(As, Bs) :-
	maplist(vec_reduce3, As, Bs).

vec_reduce3(A, B) :-
	coord_reduced(A, B).

vec_reduce3(A, A) :-
	A = value(_,_).

coord_reduced(coord(Unit, A_Debit), coord(Unit, A_Debit)).
	
coord_or_value_unit(coord(Unit,_), Unit).
coord_or_value_unit(value(Unit,_), Unit).

vec_units(Vec, Units) :-
	findall(Unit,
	(
		member(X, Vec),
		coord_or_value_unit(X, Unit)
	),
	Units0),
	sort(Units0, Units).

	
vec_filtered_by_unit(Vec, Unit, Filtered) :-
	findall(Coord,
	(
		coord_or_value_unit(Coord, Unit),
		member(Coord, Vec)
	),
	Filtered).

% Adds the two given vectors together.

vec_add(As, Bs, Cs_Reduced) :-
	assertion((flatten(As, As), flatten(Bs, Bs))),
	/*paste the two vectors togetner*/
	append(As, Bs, As_And_Bs),

	sort_into_assoc(coord_or_value_unit, As_And_Bs, Sorted),
	assoc_to_values(Sorted, Valueses),

	findall(
		Total,
		(
			member(Values, Valueses),
			semigroup_foldl(coord_merge, Values, [Total]) 
		),
		Cs_Flat
	),
	vec_reduce(Cs_Flat, Cs_Reduced).

vec_sum(Vectors, Sum) :-
	foldl(vec_add, Vectors, [], Sum).

% Subtracts the vector Bs from As by inverting Bs and adding it to As.

vec_sub(As, Bs, Cs) :-
	vec_inverse(Bs, Ds),
	vec_add(As, Ds, Cs).

% Checks two vectors for equality by subtracting the latter from the former and verifying
% that all the resulting coordinates are zero.

vec_equality(As, Bs) :-
	vec_sub(As, Bs, Cs),
	forall(member(C, Cs), is_zero(C)).

is_zero(Coord) :-
	is_zero_coord(Coord).
	
is_zero(Value) :-
	is_zero_value(Value).

is_zero([X]) :-
	is_zero(X).

/*	
is_zero_coord(coord(_, Zero1)) :-
	{Zero1 =:= 0}.
	non-cplq version for speed..*/
is_zero_coord(coord(_, Zero1)) :-
	Zero1 = 0 -> true ; Zero1 = 0.0.

is_zero_value(value(_, Zero)) :-
	is_zero_coord(coord(_, Zero)).

is_debit(coord(_, X)) :-
	X > 0.

is_debit([Coord]) :-
	is_debit(Coord).

is_credit(coord(_, X)) :-
	X < 0.

is_credit([Coord]) :-
	is_credit(Coord).

unify_coords_or_values(coord(U, D1), coord(U, D2)) :-
	unify_numbers(D1, D2).

unify_coords_or_values(value(U, V1), value(U, V2)) :-
	unify_numbers(V1, V2).

unify_numbers(A,B) :-
	(
		A = B
	->
		true
	;
		A =:= B
	).


number_coord(Unit, Number, coord(Unit, Number)).
credit_coord(Unit, Credit, coord(Unit, Number)) :- {Credit = -Number}.

dr_cr_coord(Unit, Number, Zero, coord(Unit, Number)) :- {Number >= 0, Zero = 0}.
dr_cr_coord(Unit, Zero, Credit, coord(Unit, Number)) :- {Number < 0, Zero = 0, Credit = -Number}.


/*value_debit(value(Unit, Amount), coord(Unit, Amount, Zero)) :- unify_numbers(Zero, 0).
value_credit(value(Unit, Amount), coord(Unit, Zero, Amount)) :- unify_numbers(Zero, 0).*/

coord_normal_side_value(coord(Unit, D), debit, value(Unit, D)).
coord_normal_side_value(coord(Unit, D), credit, value(Unit, V)) :- {V = -D}.

number_vec(_, Zero, []) :-
	unify_numbers(Zero, 0).
	
number_vec(Unit, Number, [Coord]) :-
	number_coord(Unit, Number, Coord).

credit_vec(Unit, Credit, [Coord]) :-
	assertion(var(Unit);atom(Unit)),
	credit_coord(Unit, Credit, Coord).


credit_isomorphism(Coord, C) :- 
	number_coord(_, D, Coord),
	C is -D.

debit_isomorphism(Coord, C) :- 
	number_coord(_, C, Coord).

coord_or_value_of_same_unit(A, B) :-
	coord_unit(A, A_Unit),
	coord_unit(B, A_Unit).
coord_or_value_of_same_unit(A, B) :-
	value_unit(A, A_Unit),
	value_unit(B, A_Unit).

coord_merge(coord(Unit, D1), coord(Unit, D2), coord(Unit, D3)) :-
	D3 is D2 + D1.
	
coord_merge(value(Unit, D1), value(Unit, D2), value(Unit, D3)) :-
	D3 is D2 + D1.

value_convert(value(Unit, Amount1), exchange_rate(_,Src,Dst,Rate), value(Unit2, Amount2)) :-
	assertion(Unit = Src),
	assertion(Unit2 = Dst),
	Unit2 = Dst,
	Amount2 is Amount1 * Rate.
	
value_multiply(value(Unit, Amount1), Multiplier, value(Unit, Amount2)) :-
	Amount2 is Amount1 * Multiplier.

value_divide(value(Unit, Amount1), Divisor, value(Unit, Amount2)) :-
	Amount2 is Amount1 / Divisor.

value_divide2(value(U1, A1), value(U2, A2), exchange_rate(xxx, U2, U1, Rate)) :-
	{A1 / A2 = Rate}.

value_subtract(value(Unit1, Amount1), value(Unit2, Amount2), value(Unit2, Amount3)) :-
	assertion(Unit1 == Unit2),
	Amount3 is Amount1 - Amount2.
	
vecs_are_almost_equal(A, B) :-
	vec_sub(A, B, C),
	maplist(coord_is_almost_zero, C).

coord_is_almost_zero(coord(_, D)) :-
	floats_close_enough(D, 0).

coord_is_almost_zero(value(_, V)) :-
	floats_close_enough(V, 0).

vector_of_coords_to_vector_of_values(_, _, [], []).
vector_of_coords_to_vector_of_values(Sd, Account_Id, [Coord|Coords], [Value|Values]) :-
	account_normal_side(Sd.accounts, Account_Id, Side),
	coord_normal_side_value(Coord, Side, Value),
	vector_of_coords_to_vector_of_values(Sd, Account_Id, Coords, Values).

split_vector_by_percent(V0, Rate, V1, V2) :-
	maplist(split_coord_by_percent(Rate), V0, V1, V2).

split_coord_by_percent(Rate, H0, H1, H2) :-
	H0 = coord(U, D0),
	D1 is D0 * Rate / 100,
	D2 is D0 - D1,
	H1 = coord(U, D1),
	H2 = coord(U, D2).

vector_unit([coord(U, _)], U).


value_debit_vec(Value, [Coord]) :-
	coord_normal_side_value(Coord, debit, Value).

value_credit_vec(Value, [Coord]) :-
	coord_normal_side_value(Coord, credit, Value).


:- multifile term_dict/2.
term_dict(
	Coord,
	coord{unit:U2, debit:D2, credit:C2}
) :-
	dr_cr_coord(U0, D0, C0, Coord),
	round_term(U0,U2),
	round_to_significant_digit(D0,D2),
	round_to_significant_digit(C0,C2).

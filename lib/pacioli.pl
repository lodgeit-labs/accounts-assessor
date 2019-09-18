% ===================================================================
% Project:   LodgeiT
% Module:    pacioli.pl
% Date:      2019-06-02
% ===================================================================

:- module(pacioli, [
		coord_unit/2,
		vec_add/3,
		vec_sum/2,
		vec_equality/2,
		vec_identity/1,
		vec_inverse/2,
		vec_reduce/2,
		vec_sub/3,
		vec_units/2,
		number_coord/3,
		number_vec/3,
		make_debit/2,
		make_credit/2,
		value_multiply/3,
		value_divide/3,
		value_subtract/3,
		value_convert/3,
		debit_isomorphism/2,
		vecs_are_almost_equal/2,
		coord_is_almost_zero/1,
		is_debit/1,
	    coord_merge/3,
	    coord_normal_side_value/3,
	    vector_of_coords_to_vector_of_values/4]).

:- use_module('utils', [
			semigroup_foldl/3,
			floats_close_enough/2,
			sort_into_dict/3,
			sort_into_assoc/3
]).

:- use_module('accounts').

:- use_module(library(clpq)).
:- use_module(library(record)).
:- use_module(library(http/json)).

:- record coord(unit, debit, credit).
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

coord_inverse(coord(Unit, A_Debit,  A_Credit), coord(Unit, A_Credit, A_Debit)).
coord_inverse(value(Unit, Value), value(Unit, Value_Inverted)) :-
	Value_Inverted is - Value.

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

coord_reduced(coord(Unit, A_Debit, A_Credit), coord(Unit, B_Debit, B_Credit)) :-
	Common_value is min(A_Debit, A_Credit),
	B_Debit is A_Debit - Common_value,
	B_Credit is A_Credit - Common_value.
	
coord_or_value_unit(coord(Unit,_,_), Unit).
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

vec_unit_value(Vec, Unit, Coord) :-
	vec_filtered_by_unit(Vec, Unit, Filtered),
	semigroup_foldl(coord_merge, Filtered, Coord).

% Adds the two given vectors together.

vec_add(As, Bs, Cs_Reduced) :-
	assertion((flatten(As, As), flatten(Bs, Bs))),
	/*paste the two vectors togetner*/
	append(As, Bs, As_And_Bs),

	sort_into_assoc(pacioli:coord_or_value_unit, As_And_Bs, Sorted),
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
/*	
is_zero_coord(coord(_, Zero1, Zero2)) :-
	{Zero1 =:= 0,
	Zero2 =:= 0}.

	non-cplq version for speed..
*/
is_zero_coord(coord(_, Zero1, Zero2)) :-
	(Zero1 = 0 -> true ; Zero1 = 0.0),
	(Zero2 = 0 -> true ; Zero2 = 0.0).

is_zero_value(value(_, Zero)) :-
	is_zero_coord(coord(_, Zero, 0)).

is_debit(coord(_, _, Zero)) :-
	{Zero =:= 0}.

is_debit([coord(_, _, Zero)]) :-
	{Zero =:= 0}.

unify_coords_or_values(coord(U, D1, C1), coord(U, D2, C2)) :-
	unify_numbers(D1, D2),
	unify_numbers(C1, C2).

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

	
make_debit(value(Unit, Amount), coord(Unit, Amount, 0)).
make_debit(coord(Unit, Dr, Zero), coord(Unit, Dr, 0)) :- Zero =:= 0.
make_debit(coord(Unit, Zero, Cr), coord(Unit, Cr, 0)) :- Zero =:= 0.

make_credit(value(Unit, Amount), coord(Unit, 0, Amount)).
make_credit(coord(Unit, Dr, Zero), coord(Unit, 0, Dr)) :- Zero =:= 0.
make_credit(coord(Unit, Zero, Cr), coord(Unit, 0, Cr)) :- Zero =:= 0.

number_coord(Unit, Number, coord(Unit, Debit, Credit)) :-
	{Number =:= Debit - Credit}.

coord_normal_side_value(coord(Unit, D, C), debit, value(Unit, V)) :-
	{V =:= D - C}.

coord_normal_side_value(coord(Unit, D, C), credit, value(Unit, V)) :-
	{V =:= C - D}.

number_vec(_, Zero, []) :-
	unify_numbers(Zero, 0).
	
number_vec(Unit, Number, [Coord]) :-
	number_coord(Unit, Number, Coord).

	
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

coord_merge(coord(Unit, D1, C1), coord(Unit, D2, C2), coord(Unit, D3, C3)) :-
	D3 is D2 + D1,
	C3 is C2 + C1.
	
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

value_subtract(value(Unit1, Amount1), value(Unit2, Amount2), value(Unit2, Amount3)) :-
	assertion(Unit1 == Unit2),
	Amount3 is Amount1 - Amount2.
	
vecs_are_almost_equal(A, B) :-
	vec_sub(A, B, C),
	maplist(coord_is_almost_zero, C).

coord_is_almost_zero(coord(_, D, C)) :-
	floats_close_enough(D, 0),
	floats_close_enough(C, 0).

coord_is_almost_zero(value(_, V)) :-
	floats_close_enough(V, 0).

vector_of_coords_to_vector_of_values(_, _, [], []).
vector_of_coords_to_vector_of_values(Sd, Account_Id, [Coord|Coords], [Value|Values]) :-
	account_normal_side(Sd.accounts, Account_Id, Side),
	coord_normal_side_value(Coord, Side, Value),
	vector_of_coords_to_vector_of_values(Sd, Account_Id, Coords, Values).

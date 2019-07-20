% ===================================================================
% Project:   LodgeiT
% Module:    pacioli.pl
% Date:      2019-06-02
% ===================================================================

:- module(pacioli, [vec_add/3,
		    vec_equality/2,
		    vec_identity/1,
		    vec_inverse/2,
		    vec_reduce/2,
		    vec_sub/3,
		    vec_units/2,
		    number_coord/3,
		    make_debit/2,
		    make_credit/2,
		    value_multiply/3,
			debit_isomorphism/2,
			is_debit/1]).

:- use_module(utils, [semigroup_foldl/3]).

:- use_module(library(clpr)).
		    
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
coord_inverse(unit(Unit, Value), unit(Unit, Value_Inverted)) :-
	Value_Inverted is - Value.

% Each coordinate of a vector can be replaced by other coordinates that equivalent for the
% purposes of the computations carried out in this program. This predicate reduces the
% coordinates of a vector into a canonical form.
%  - returns vector with same coordinates, just minimized by substracting a common value from
%    debit and credit, so that one of them becomes 0, for example 150,50 -> 100,0.
% if both debit and credit is 0, the coord is removed.
/* fixme: rename to vec_reduce_coords, define vec_reduce(X) as vec_add(X, [])? */
vec_reduce(As, Bs) :-
	findall(B,
		(
			member(coord(Unit, A_Debit, A_Credit), As),
			Common_value = min(A_Debit, A_Credit),
			B_Debit is A_Debit - Common_value,
			B_Credit is A_Credit - Common_value,
			B = coord(Unit, B_Debit, B_Credit),
			\+ is_zero(B)
		)
		;
		(
			member(B, As),
			B = value(_,_)
		),
		Bs
	),!.


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
		member(Coord, Vec),
		coord_or_value_unit(Coord, Unit)
	),
	Filtered).

vec_unit_value(Vec, Unit, Coord) :-
	vec_filtered_by_unit(Vec, Unit, Filtered),
	semigroup_foldl(coord_merge, Filtered, Coord).

% Adds the two given vectors together.

vec_add(As, Bs, Cs_Reduced) :-
	assertion((flatten(As, As), flatten(Bs, Bs))),
	append(As, Bs, As_And_Bs),
	vec_units(As_And_Bs, Units),
	findall(Coord,
	(
		member(Unit, Units),
		vec_unit_value(As_And_Bs, Unit, Coord)
	)
	,Cs),
	flatten(Cs, Cs_Flat),
	vec_reduce(Cs_Flat, Cs_Reduced).

% Subtracts the vector Bs from As by inverting Bs and adding it to As.

vec_sub(As, Bs, Cs) :-
	vec_inverse(Bs, Ds),
	vec_add(As, Ds, Cs).

% Checks two vectors for equality by subtracting the latter from the former and verifying
% that all the resulting coordinates are zero.

vec_equality(As, Bs) :-
	vec_sub(As, Bs, Cs),
	forall(member(C, Cs), is_zero(C)).

is_zero(coord(_, Zero1, Zero2)) :-
	{Zero1 =:= 0,
	Zero2 =:= 0}.
is_zero(value(_, Zero)) :-
	is_zero(coord(_, Zero, 0)).

is_debit(coord(_, _, Zero)) :-
	{Zero =:= 0}.

is_debit([coord(_, _, Zero)]) :-
	{Zero =:= 0}.

	
make_debit(value(Unit, Amount), coord(Unit, Amount, 0)).
make_debit(coord(Unit, Dr, Zero), coord(Unit, Dr, 0)) :- Zero =:= 0.
make_debit(coord(Unit, Zero, Cr), coord(Unit, Cr, 0)) :- Zero =:= 0.

make_credit(value(Unit, Amount), coord(Unit, 0, Amount)).
make_credit(coord(Unit, Dr, Zero), coord(Unit, 0, Dr)) :- Zero =:= 0.
make_credit(coord(Unit, Zero, Cr), coord(Unit, 0, Cr)) :- Zero =:= 0.

/* fixme, rename to number_coord*/
number_coord(Unit, Integer, coord(Unit, Debit, Credit)) :-
	{Integer =:= Debit - Credit}.

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

coord_unit(coord(Unit, _, _), Unit).
value_unit(value(Unit, _), Unit).

coord_merge(coord(Unit, D1, C1), coord(Unit, D2, C2), coord(Unit, D3, C3)) :-
	D3 is D2 + D1,
	C3 is C2 + C1.
	
coord_merge(value(Unit, D1), value(Unit, D2), value(Unit, D3)) :-
	D3 is D2 + D1.


value_multiply(value(Unit, Amount1), Multiplier, value(Unit, Amount2)) :-
	Amount2 is Amount1 * Multiplier.

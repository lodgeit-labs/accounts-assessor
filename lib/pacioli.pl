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
		    integer_to_coord/3]).

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
/*
vec_inverse(As, Bs) :-
	findall(C,
		(member(	coord(Unit, A_Debit,  A_Credit), As),
		C = 		coord(Unit, A_Credit, A_Debit)),
		Bs).
this method doesn't preserve the bindings of variables - if for example Unit in
one coord in As is unbound, Bs will contain that coord inverted, but with Unit a 
fresh variable, not linked to the original. So if later Unit is bound, this is not
reflected in the returned vector. 
Moreover, this method doesn't work both ways - it will not produce As from Bs,
it will go into an infinite loop instead.
*/

vec_inverse(As, Bs) :-
	maplist(coord_inverse, As, Bs).

coord_inverse(coord(Unit, A_Debit,  A_Credit), coord(Unit, A_Credit, A_Debit)).
coord_inverse(unit(Unit, Value), unit(Unit, Value_Inverted)) :-
	Value_Inverted is - Value.

% Each coordinate of a vector can be replaced by other coordinates that equivalent for the
% purposes of the computations carried out in this program. This predicate reduces the
% coordinates of a vector into a canonical form.
%  - returns vector with same coordinates, just minimized by substracting a common value from
%    debit and credit, so that one becomes 0, for example 150,50 -> 100,0 
vec_reduce(As, Bs) :-
	findall(B,
		(member(coord(Unit, A_Debit, A_Credit), As),
		Common_value = min(A_Debit, A_Credit),
		B_Debit is A_Debit - Common_value,
		B_Credit is A_Credit - Common_value,
		B = coord(Unit, B_Debit, B_Credit),
		\+ is_zero(B)),
		Bs
	),!.

/* 'value' version */
vec_reduce(As, As).


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

integer_to_coord(Unit, Integer, coord(Unit, Debit, Credit)) :-
	{Integer =:= Debit - Credit}.

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

test0 :-
	vec_units([coord(aud, _,_), coord(aud, _,_), coord(usd, _,_)], Units0), Units0 = [aud, usd],
	vec_units([], []),
	vec_units([coord(aud, 5,7), coord(aud, _,_), coord(Usd, _,_)], [aud, Usd]),
	coord_merge(coord(Unit, 1, 2), coord(Unit, 3, 4), coord(Unit, 4, 6)),
	semigroup_foldl(coord_merge, [], []),
	semigroup_foldl(coord_merge, [value(X, 5)], [value(X, 5)]),
	semigroup_foldl(coord_merge, [coord(x, 4, 5), coord(x, 4, 5), coord(x, 4, 5)], [coord(x, 12, 15)]),
	\+semigroup_foldl(coord_merge, [coord(y, 4, 5), coord(x, 4, 5), coord(x, 4, 5)], _),
	vec_add([coord(a, 5, 1)], [coord(a, 0.0, 4)], []),
	vec_add([coord(a, 5, 1), coord(b, 0, 0.0)], [coord(b, 7, 7), coord(a, 0.0, 4)], []),
	vec_add([coord(a, 5, 1), coord(b, 1, 0.0)], [coord(a, 0.0, 4)], [coord(a, 5.0, 5), coord(b, 1, 0.0)]),
	vec_add([coord(a, 5, 1), coord(b, 1, 0.0), coord(a, 8.0, 4)], [], [coord(a, 13.0, 5), coord(b, 1, 0.0)]),
	true.

:- test0.

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
		    vec_sub/3]).

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
	findall(C,
		(member(	coord(Unit, A_Debit,  A_Credit), As),
		C = 		coord(Unit, A_Credit, A_Debit)),
		Bs).

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
		B = coord(Unit, B_Debit, B_Credit)),
		Bs).

% Adds the two given vectors together.

vec_add(As, Bs, Cs_Reduced) :-
	findall(C,
		(
		% all coords of units only found in A
		(member(coord(Unit, A_Debit, A_Credit), As),
		\+ member(coord(Unit, _, _), Bs),
		C = coord(Unit, A_Debit, A_Credit));
		
		% all coords of units only found in B
		(member(coord(Unit, B_Debit, B_Credit), Bs),
		\+ member(coord(Unit, _, _), As),
		C = coord(Unit, B_Debit, B_Credit));

		% all coords of units found in both, add debits and credits
		(member(coord(Unit, A_Debit, A_Credit), As),
		member(coord(Unit, B_Debit, B_Credit), Bs),
		Total_Debit is A_Debit + B_Debit,
		Total_Credit is A_Credit + B_Credit,
		C = coord(Unit, Total_Debit, Total_Credit))),
		Cs),
	vec_reduce(Cs, Cs_Reduced).

% Subtracts the vector Bs from As by inverting Bs and adding it to As.

vec_sub(As, Bs, Cs) :-
	vec_inverse(Bs, Ds),
	vec_add(As, Ds, Cs).

% Checks two vectors for equality by subtracting the latter from the former and verifying
% that all the resulting coordinates are zero.

vec_equality(As, Bs) :-
	vec_sub(As, Bs, Cs),
	forall(member(C, Cs), C = coord(_, 0, 0)).


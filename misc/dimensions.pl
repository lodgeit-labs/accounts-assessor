:- use_module(library(clpq)).
/*
Operations:
 +, -
	can only be done on quantities of the same dimension
 =, <, =<, >, >=
	can only be done on quantities of the same dimension
 /, *
 ^c

*/


/*
Dimension
 the system of dimensions should form a commutative group under * and /
 basically any given compound dimension is like a signed multi-set, ex..
 {m^2/(kg*s^2)) ~ 
 
 {
	m : 2,
	kg: -1,
	s: -2
 }

 RDF representation:
 d a dimension
 d mass 2.
 d kg -1.
 d s -2.

 Can't use a fixed set of dimensions, so we can't use a representation like
 ex...
 1 = _{
   m: 0,
   kg: 0,
   s: 0
 }

 probably need 1 = {}, with dimensions arbitrarily extensible, and if any dimensions
 are taken to the power of 0 then they get normalized away

 
*/


% note that this follows exactly the same logic as multiplying any two
% monomials, taking the variables in the monomial to represent the dimensions

dim_value(D, Dim, D_Exp) :-
		get_dict(Dim, D, D_Exp)
	->  true
	;   D_Exp = 0.

dim_inverse(D, D_Inv) :-
	dict_keys(D, Dims),
	findall(
		Dim-Exp,
		(
			member(Dim, Dims),
			dim_value(D, Dim, D_Exp),
			Exp is -D_Exp
		),
		D_List
	),
	dict_pairs(D_Inv, _, D_List).

dim_multiply(D1, D2, D_Out) :-
	dict_keys(D1, D1_Dims),
	dict_keys(D2, D2_Dims),
	union(D1_Dims, D2_Dims, Dims),
	findall(
		Dim-Exp,
		(
			member(Dim, Dims),
			dim_value(D1, Dim, D1_Exp),
			dim_value(D2, Dim, D2_Exp),
			Exp is D1_Exp + D2_Exp,
			Exp \= 0
		),
		D_List
	),
	dict_pairs(D_Out, _, D_List).

dim_divide(D1, D2, D_Out) :-
	dim_inverse(D2, D2_Inv),
	dim_multiply(D1, D2_Inv, D_Out).


% might not apply correctly to non-normalized inputs; needs checking.
dim_equal(D1, D2) :-
	dict_pairs(D1, _, D1_Pairs),
	dim_equal_helper(D1_Pairs, D2).

dim_equal_helper([], _).
dim_equal_helper([Dim-Exp | Rest], D2) :-
	get_dict(Dim, D2, Exp),
	dim_equal_helper(Rest, D2).

/*
Quantity
 a system of quantities over a given system of units and dimensions is a vector space whose basis is those
 units and whose dimensions are those dimensions... roughly speaking... though I'm not sure the vector
 space framework would directly/properly account for dimensions rased to negative powers

 
*/

base_dimension(inch,length).
base_dimension(foot,length).
base_dimension(second,time).
base_dimension(minute,time).
base_dimension(hour, time).
base_dimension(day, time).
base_dimension(week, time).
base_dimension(month, time).

dimension_helper([], X, X).
dimension_helper([Unit-Exp | Rest], D_Current, D_Out) :-
	base_dimension(Unit, Dimension),
	D_Next = D_Current.put([Dimension = Exp]),
	dimension_helper(Rest, D_Next, D_Out).

dimension(Basis, Q, D) :-
	quantity_normalize(Basis, Q, (_, U_Normal)),
	dict_pairs(U_Normal, _, U_Pairs),
	dimension_helper(U_Pairs, _{}, D).

% standard ratio order, as in "foot:inch = 12"
% this is opposite to the "per" ordering, i.e. "12 inches per foot"
base_ratio(foot, inch, 12).
base_ratio(minute, second, 60).
base_ratio(hour, minute, 60).
base_ratio(day, hour, 24).
base_ratio(week, day, 7).
base_ratio(month, week, 4).
base_ratio(year, month, 12).

ratio(X, X, 1) :- !.
ratio(X, Y, Ratio) :- base_ratio(X, Y, Ratio), !.
ratio(X, Y, Ratio) :- base_ratio(Y, X, Inv_Ratio), Ratio is 1/Inv_Ratio, !.
ratio(X, Y, Ratio) :- base_ratio(X, Z, Ratio1), ratio(Z, Y, Ratio2), !, Ratio is Ratio1 * Ratio2.

product([], 1).
product([X | Rest], Product) :-
		X = 0
	-> 	Product = 0
	; (
		product(Rest, Rest_Product),
		Product is X * Rest_Product
	).

clp_product([], 1).
clp_product([X], X).
clp_product([X, Y], Product) :- {Product = X * Y}.
clp_product([X, Y, Z | Rest], Product) :-
	{Product = X * Rest_Product},
	clp_product([Y, Z | Rest], Rest_Product).

/*
probably not the most elegant code for expressing arithmetic on quantities...
*/



/*
this probably shouldn't have to exist, because powers of a base dimension
are really just multiple dimensions, ex.. a space of dimension L^3 you can move
around in 3... dimensions, i.e. there are 3 independent axes, and we should be
able to vary the units on each axis independently.
*/
quantity_merge_duplicates([], X, X).
quantity_merge_duplicates([Unit-Exp | Rest], U_Current, U_Out) :-
	(	get_dict(Unit, U_Current, Cur_Exp)
	->	Next_Exp is Exp + Cur_Exp
	;	Next_Exp = Exp),
	(
		Next_Exp = 0
	->	del_dict(Unit, U_Current, _, U_Next)
	; 	U_Next = U_Current.put([Unit = Next_Exp])
	),
	quantity_merge_duplicates(Rest, U_Next, U_Out).	

/*
this is basically just a change of basis from U -> Basis
change of basis effectively models unit conversion;
*/


quantity_normalize(Basis, (V, U),  (V_Normal, U_Normal)) :-
	dict_keys(U, Units),
	findall(
		[Factor, Base_Unit-Exp],
		(
			member(Unit, Units),
			Exp = U.Unit,
			base_dimension(Unit, Dim),
			
			(	get_dict(Dim, Basis, Base_Unit)
			-> 	true
			;	Base_Unit = Unit),
			ratio(Unit, Base_Unit, Base_Ratio),
			Factor is Base_Ratio^Exp
		),
		Conversions
	),
	maplist(nth0(0), Conversions, V_List),
	maplist(nth0(1), Conversions, U_List),
	quantity_merge_duplicates(U_List, _{}, U_Normal),
	append(V_List, [V], Vs),
	clp_product(Vs, V_Normal).

quantity_inverse((V, U), (V_Inv, U_Inv)) :-
	V_Inv is 1/V,
	dim_inverse(U, U_Inv).

quantity_multiply(Basis, (V1, U1), (V2, U2), (V_Out, U_Out)) :-
	quantity_normalize(Basis, (V1, U1), (V1_Normal, U1_Normal)),
	quantity_normalize(Basis, (V2, U2), (V2_Normal, U2_Normal)),
	% once the units are normalized into the same basis, dim_multiply can apply
	dim_multiply(U1_Normal, U2_Normal, U_Out),
	V_Out is V1_Normal * V2_Normal.

quantity_divide(Basis, Q1, Q2, Q_Out) :-
	quantity_inverse(Q2, Q2_Inv),
	quantity_multiply(Basis, Q1, Q2_Inv, Q_Out).

quantity_add(Basis, Q1, Q2, (V_Out, U_Out)) :-
	dimension(Basis, Q1, D1),
	dimension(Basis, Q2, D2),
	dim_equal(D1, D2),
	quantity_normalize(Basis, Q1, (V1_Normal, U_Out)),
	quantity_normalize(Basis, Q2, (V2_Normal, _)),
	V_Out is V1_Normal + V2_Normal.

quantity_subtract(Basis, Q1, (V2, U2), Q_Out) :-
	quantity_add(Basis, Q1, (-V2, U2), Q_Out).


/*
Dealing with mixed units like 1 minute 30 seconds
* should be put in a higher level of abstraction, but treated in a similar way as a standard basis
* represents addition: 1 minute + 30 seconds; maintaining it in that form should be the responsibility of
%   symbolic computation.
* can convert this into any given basis, or back into this representation
	* can currently figure out 90 seconds from 1 minute + 30 seconds but not vice versa
	  the reason: there's no constraints to indicate that it should be trying to use up
	  as many minutes as possible and only using seconds to fill in the remainder; this is
	  generalization of the division algorithm/problem; it can be represented as a
	  minimization/maximization, ex.. maximization of the # of minutes that are less than
	  90 seconds
* similar logic to radix representation of numbers


*/

/*
Basis
* change of basis
* vector spaces?
* fahrenheit <-> celsius conversion (affine transformation, rather than the linear "multiply by constant")
* affine transformation can be decomposed into a scaling of the basis vectors and a translation of the origin
* we will simply generalize to "move between any two coordinate systems on the same space"


*/

/*
Naming
* plurals
*/

plural(foot, feet).
plural(inch, inches).
plural(second, seconds).
plural(minute, minutes).
plural(hour, hours).
plural(day, days).
plural(week, weeks).
plural(month, months).
plural(year, years).

/*
Multiplier prefixes
*/
multiplier(micro, 0.000001).
multiplier(milli, 0.001).
multiplier(centi, 0.01).
multiplier(deci, 0.1).
multiplier(dozen, 12).
multiplier(kilo, 1000).
multiplier(mega, 1000000).
multiplier(giga, 1000000000).



/*
ex.

?- dim_solve((1, _{foot:1} + (3, _{inch:1}) = (X, _{inch:1}).
X = 15.


	% find all the dimensional quantities and their associated dimensions and units
	% for each dimension involved
	%  find a unit for it
	%  normalize every other quantity in that dimension to that unit
	%  this will yield conversion factors that get multiplied to the values
	%  symbolically replace quantity values with value multiplied by conversion factor
	% this should yield a new formula with quantities in terms of the selected basis
	% since the units are all aligned now, we can drop the dimensions from the formula
	% and get a pure numeric formula, which we can then feed to clp(q)

	% we also have constraints on/between the dimensions themselves, so if we try to
	% add/compare two quantities, we need to add constraints that their dimensions are equal
	% can maybe assert dimensional constraints using clp(fd) ?


*/
dim_solve(Formula, Tolerance, Errors) :-
	dim_solve_helper(Formula, _{}, Tolerance, Errors).

% needs to add constraints on the dimensions; could do that with proper existentials
% could maybe do that with clp(fd)
dim_solve_helper(A = B, Current_Basis, Tolerance, Errors) :-
	dim_solve_formula(A, Current_Basis, Basis_A, A_Reduced, [], A_Inputs),
	dim_solve_formula(B, Basis_A, _, B_Reduced, A_Inputs, Inputs),
	{A_Reduced = B_Reduced},
	dim_solve_bind_inputs(Inputs, Tolerance, Errors).

/*
* basic tolerance: bind the values into the constraints one at a time. if any fail, backtrack
  and check whether or not it's close enough to the value already there.
  so we need to collect & apply constraints before-hand, and have some kind of association between
  query variables and constraint variables

* basic error-tracking
*/

dim_solve_bind_inputs([], _, []).
dim_solve_bind_inputs([X:V | Rest], Tolerance, [Error | Rest_Errors]) :-
	{X = V + Error},
	(	{Error = 0}
	->	true
	;	true),
	{abs(Error) < Tolerance},
	dim_solve_bind_inputs(Rest, Tolerance, Rest_Errors).

% needs to add constraints on the dimensions
dim_solve_formula(A + B, Current_Basis, New_Basis, A_Reduced + B_Reduced, Current_Inputs, Next_Inputs) :-
	dim_solve_formula(A, Current_Basis, Basis_A, A_Reduced, Current_Inputs, A_Inputs),
	dim_solve_formula(B, Basis_A, New_Basis, B_Reduced, A_Inputs, Next_Inputs).

% needs to add constraints on the dimensions
dim_solve_formula(A - B, Current_Basis, New_Basis, A_Reduced - B_Reduced, Current_Inputs, Next_Inputs) :-
	dim_solve_formula(A, Current_Basis, Basis_A, A_Reduced, Current_Inputs, A_Inputs),
	dim_solve_formula(B, Basis_A, New_Basis, B_Reduced, A_Inputs, Next_Inputs).

dim_solve_formula(A * B, Current_Basis, New_Basis, A_Reduced * B_Reduced, Current_Inputs, Next_Inputs) :-
	dim_solve_formula(A, Current_Basis, Basis_A, A_Reduced, Current_Inputs, A_Inputs),
	dim_solve_formula(B, Basis_A, New_Basis, B_Reduced, A_Inputs, Next_Inputs).

dim_solve_formula(A / B, Current_Basis, New_Basis, A_Reduced / B_Reduced, Current_Inputs, Next_Inputs) :-
	dim_solve_formula(A, Current_Basis, Basis_A, A_Reduced, Current_Inputs, A_Inputs),
	dim_solve_formula(B, Basis_A, New_Basis, B_Reduced, A_Inputs, Next_Inputs).


dim_solve_formula((V, U), Current_Basis, New_Basis, V_Reduced, Current_Inputs, Next_Inputs) :-
	(	var(V) 
	-> 	(New_V = V, New_Inputs = [])
	; 	(New_V = X, New_Inputs = [V:X])),
	append(Current_Inputs, New_Inputs, Next_Inputs),
	dict_keys(U, Units),
	findall(
		Dim-Unit,
		(
			member(Unit, Units),
			base_dimension(Unit, Dim),
			\+get_dict(Dim, Current_Basis, _)
		),
		New_Units_List
	),
	dict_pairs(New_Units, _, New_Units_List),
	New_Basis = Current_Basis.put(New_Units),
	quantity_normalize(New_Basis, (New_V, U), (V_Reduced, _)).

/*
Date-time handling
* describe an arbitrary decomposition of a dimension into a collection of intervals
* implement a "per variable-length-interval" dimensions semantics
* offload date-time handling to something that generates these intervals over the time dimension


*/

	

/*
Vector space
* linear independence
* spanning

Dimensional quantities are measures of volumes; take ex..
 a 2 ft * 3 ft box
what's the measurement of it's size:
 6 ft^2
If we position a corner of the box at the origin or a coordinate system, 
we can represent it by the vector (2,3). So any box/vector can be associated 
to a dimensional quantity by taking the product of its sides/components, respectively.

*/


/*
Numerics handling
* representations and numeric tower:
	* rational
	* real
	* float
	* pacioli
	* reconciliation of the levels of the numeric tower related to reconciliation of the inferencers
	  over the different levels
* arbitrary precision; fixed & unbounded
*/

/*
Transfer-like dimensions
* this is maybe more like, there's a graph external to the dimensions system, and
  the quantities in the graph just have certain dimensions, but we can consider ex. expressions such as
  "$150 from A to B"
*/

/*
Dimensionless quantities
* ratios
* transcendentals
*/

/*
Dimensional quantities, size, measurement, and measure theory
* does length1 + length2 equal the measure of the combined lengths? not if they overlap.
* so, some of the basic treatment of dimensional analysis in terms of an arithmetic
  system seems somewhat lacking in a way that would perhaps be handled better in a
  set-theoretic or measure-theoretic framework. this starts to give a more complete
  picture of the situation and fills in some semantic details that are missing from
  the pure arithmetic system.
* in general these considerations come up when we try to examine the treatment of
  absolute concrete quantities, rather than relative/hypothetical/abstract/numeric quantities
  for example, a specific area of land, rather than an abstract numeric quantity representing
  a generic amount of area, or even a generic amount of area of land
* we can relate the two through the concept of a measurement, i.e. some measuring process
  applied to the specific area of land derived a measurement yielding the generic amount of area
  so we can differentiate what we mean in the expression area1 + area2
  do we mean the sum of the measurements, or the measurement of the sum?
  i.e.:
  measure(area1) + measure(area2)
  vs.
  measure(area1 + area2) 
  _+_ in the latter case should be roughly interpreted as union of sets (maybe more adequately "volumes"
  or even "manifolds") describing the two areas. 

  this expressive abstraction lets us cleanly deal with issues like overlap, and other aspects
  of ensuring that our numeric calculations respect the semantics of the actual concepts they're
  representing. also provides a partial bridge between the numerics and the semantics, which
  could possibly be useful for the inferencer.

  for a formal system modeling this concept of "measurement", measure-theory seems natural.

  measure theory also comes up in the mathematical formalization of calculus, which seems to be
  entering into our equations, and particularly in relationship to dimensional quantities.
		
  so perhaps this abstraction can be exploited for practical utility
*/


/*
We might also expect dimensional analysis to have some basic relationships with type theory.
*/

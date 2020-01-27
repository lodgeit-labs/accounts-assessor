:- use_module(library(clpq)).

:-  op(  1,  fx,   [ * ]).
:- dynamic debug_level/1.

'*'(_).
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
 dimensions are distinguished from units/quantities with those dimensions
 the system of dimensions should form a commutative group under * and /
 basically any given compound dimension is like a signed multi-set, ex..

 dimensions for velocity would be: L/T
 dimensions for energy would be: (M*L^2)/(T^2) ~ 

 {
	L : 2, % length
	M: 1, % mass
	T: -2  % time
 }

 RDF representation:
 d a dimension
 d length 2.
 d mass -1.
 d time -2.

 Can't use a fixed set of dimensions, so we can't use a representation like
 ex...
 1 = _{
   length: 0,
   mass: 0,
   time: 0
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

% units for length
base_dimension(inch, length).
base_dimension(foot, length).

% units for time
base_dimension(second, time).
base_dimension(minute, time).
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

% calculate a conversion factor/ratio between any two units of the same dimension though i guess
% there's no assertion anywhere forcing same dimension here
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


/* I don't actually use either plurals or multipliers yet but we should consider how to incorporate them */
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

dim_solve_formulas(Formulas, Tolerance, Errors) :-
	dim_solve_prepare_formulas(Formulas, Inputs),
	dim_solve_bind_inputs(Inputs, Tolerance, Errors).

dim_solve_prepare_formulas(Formulas, Inputs) :-
	dim_solve_prepare_formulas_helper(Formulas, _{}, _, [], Inputs).

dim_solve_prepare_formulas_helper([], _, _, Inputs, Inputs).
dim_solve_prepare_formulas_helper([Formula | Formulas], Current_Basis, Basis, Current_Inputs, Inputs) :-
	dim_solve_helper(Formula, Current_Basis, Next_Basis, Current_Inputs, Next_Inputs),
	dim_solve_prepare_formulas_helper(Formulas, Next_Basis, Basis, Next_Inputs, Inputs). 

/*
dim_solve(Formula, Tolerance, Errors) :-
	dim_solve_helper(Formula, _{}, Tolerance, Errors).
*/

% needs to add constraints on the dimensions; could do that with proper existentials
% could maybe do that with clp(fd)
dim_solve_helper(A = B, Current_Basis, Next_Basis, Current_Inputs, Next_Inputs) :-
	dim_solve_formula(A, Current_Basis, Basis_A, A_Reduced, Current_Inputs, A_Inputs),
	dim_solve_formula(B, Basis_A, Next_Basis, B_Reduced, A_Inputs, Next_Inputs),
	{A_Reduced = B_Reduced}.
	%dim_solve_bind_inputs(Inputs, Tolerance, Errors).

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
	% if V is a constant, replace it with a fresh variable and collect an association between this constant
	% the new variable and add it to the current list of associations
	(	var(V) 
	-> 	(New_V = V, New_Inputs = [])
	; 	(New_V = X, New_Inputs = [V:X])),
	append(Current_Inputs, New_Inputs, Next_Inputs),

	% find all dimensions not currently represented by any unit in the current basis and add them
	% to the current basis
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

	% normalize this quantity against the new basis
	quantity_normalize(New_Basis, (New_V, U), (V_Reduced, _)).


debug_level(0).


debug(X, N) :-
	((
		debug_level(M),
		N =< M
	) -> ( 
		call(X)
	) ; (
		true
	)).

set_debug(N) :-
	retract(debug_level(_)),
	assertz(debug_level(N)).

/*
Debugging:
* State
	* doc
	* rules
	* constraints
	* execution path:
		round = 3
		rule = {X p Z} <= {X a Y. Y p Z}
		body item = Y p Z (or 2)
		fact = 
* Execution trace
* Breakpoints
* Steps
* Timing
* Fine-grained selective debugging output

Optimization
* Triple indexing

Input format

*/


/*
Chase
*/
chase(KB, Results, Max_Depth) :-
	% make_kb(KB, Rules) % facts will go into doc, any constraints in the facts will be applied
	% separate tuple-generating constraints from arithmetic constraints
	% apply all tuple-generating constraints first, then apply arithmetic constraints, so the arithmetic
	%   constraints can apply to the results of the tuple-generating constraints
	make_kb(KB, New_KB, Max_Depth),
	format("KB: ~n", []),
	print_kb(New_KB),
	chase_kb(New_KB, Results),
	print_facts(Results.facts).


chase_kb(KB, New_KB) :-
	format("~nChase round: ~w~n", [KB.depth]),
	%format("Facts: ~w~n", [Facts]),
	copy_term(KB.facts, Original_Facts),
	chase_round(KB, Next_KB),
	%format("Original facts: ~w~n", [Original_Facts]),
	% because vars in the fact-set have been bound, they compare == to the values they've
	% been bound to, so we can't tell using just == that the new fact set is different from
	% the original. in order for this method of comparison to work we have to preserve the
	% original fact-set somehow.
	% there are other ways to handle this though, for example passing a flag which we toggle
	% whenever there's been a change to the fact-set.
	(
		(

		 % chase should stop when there's not enough information to determine that the new set of facts is not
		 % equivalent to the previous set of facts
		 \+(fact_sets_equal(Original_Facts, Next_KB.facts)),
		 KB.depth < KB.max_depth
		)
	-> 	(
		 format("Done chase round:~n", []),
		 Next_Depth is KB.depth + 1,
		 Next_KB2 = Next_KB.put(_{depth:Next_Depth}),
		 chase_kb(Next_KB2, New_KB)
		)
	;	(
		 format("~nChase finished after ~w rounds:~n", [KB.depth]),
		 New_KB = Next_KB
		)
	).


chase_round(KB, New_KB) :-
	format("Chase round: ~w~n", [KB.depth]),
	
	maplist(chase_rule(KB),KB.fact_rules,Heads_Nested),
	flatten(Heads_Nested, Heads),
	format("Heads: ~w~n~n", [Heads]),
	append(KB.facts, Heads, Next_Facts_List),
	to_set('==', Next_Facts_List, Next_Facts),
	Next_KB = KB.put(_{facts:Next_Facts}),
	format("Next_KB: ~w~n~n", [Next_KB]),

	maplist(chase_rule(Next_KB),KB.constraint_rules,Constraints_Nested),
	format("Constraints_Nested: ~w~n", [Constraints_Nested]),
	flatten(Constraints_Nested, Constraints),
	append(KB.constraints, Constraints, Next_Constraints_List),
	New_KB0 = Next_KB.put(_{constraints:Next_Constraints_List}),
	to_set('==', New_KB0.facts, New_Facts_Set),
	New_KB = New_KB0.put(_{facts:New_Facts_Set}),

	* format("New KB: ~w~n", [New_KB]).


chase_head_facts([], []).
chase_head_facts([Head|Heads], [Head|Head_Facts]) :- Head = fact(_,_,_), chase_head_facts(Heads, Head_Facts).
chase_head_facts([Head|Heads], Facts) :- Head \= fact(_,_,_), chase_head_facts(Heads, Facts).

chase_head_constraints([], []).
chase_head_constraints([Head|Heads], [Head|Head_Constraints]) :- Head \= fact(_,_,_), chase_head_constraints(Heads, Head_Constraints).
chase_head_constraints([Head|Heads], Constraints) :- Head = fact(_,_,_), chase_head_constraints(Heads, Constraints).

chase_apply_constraints([]).
chase_apply_constraints([Constraint | Rest]) :- 
	{Constraint},
	chase_apply_constraints(Rest).

% match the rule against the fact-set treating distinct variables in the fact-set as distinct fresh constants
% when asserting the head constraints, treat any variables bound from the fact-set as actual variables
chase_rule(KB, Rule, Heads) :-
	Rule = (_ :- Body),
	chase_rule_helper2(KB.facts, Rule, Body, KB.facts, [], [], Heads).

% if we match all the body items, succeed
chase_rule_helper2(_, Rule, [], _, Current_Subs, Current_Heads, [New_Head | Current_Heads]) :-
	Rule = (Head :- _),
	%existential vars will be fresh; universal vars will be bound with the same bindings as found in the body
	copy_facts_with_subs2(Head, Current_Subs, New_Head, _).

% we've tried one body item against all the facts
chase_rule_helper2(_, _, [Body_Item | _], [], _, Current_Heads, Current_Heads).

% still more facts, still more body items
chase_rule_helper2(Facts, Rule, [Body_Item|Rest], [Fact | Rest_Facts], Current_Subs, Current_Heads, New_Heads) :-
	Body_Item = fact(_,_,_),
	((
		match_fact(Body_Item, Fact, Current_Subs, New_Subs)
	) -> (
		% body item match, recurse over rest of body
		chase_rule_helper2(Facts, Rule, Rest, Facts, New_Subs, Current_Heads, Next_Heads)
	) ; (
		% no match, no updates
		Next_Heads = Current_Heads
	)),
	% recurse over rest of facts, repeating the same body item
	chase_rule_helper2(Facts, Rule, [Body_Item|Rest], Rest_Facts, Current_Subs, Next_Heads, New_Heads).

chase_rule_helper2(Facts, Rule, [Body_Item|Rest], _, Current_Subs, Current_Heads, New_Heads) :-
	Body_Item \= fact(_,_,_),
	((
		check_body_constraint(Body_Item, Current_Subs, New_Subs)
	) -> (
		chase_rule_helper2(Facts, Rule, Rest, Facts, New_Subs, Current_Heads, New_Heads)
	) ; (
		New_Heads = Current_Heads
	)).

/*
matching between bodies and fact-set
* body variables
*/

match_fact(BI, Fact, Subs, New_Subs) :-
	BI =.. BI_Terms,
	Fact =.. Fact_Terms,
	match_args(BI_Terms, Fact_Terms, Subs, New_Subs).

match_args([], [], Subs, Subs).
match_args([BI_Arg | BI_Args], [Fact_Arg | Fact_Args], Subs, New_Subs) :-
	match_arg(BI_Arg, Fact_Arg, Subs, Next_Subs),
	match_args(BI_Args, Fact_Args, Next_Subs, New_Subs).

match_arg(BI_Arg, Fact_Arg, Subs, Subs) :-
	nonvar(BI_Arg),
	BI_Arg == Fact_Arg.

match_arg(BI_Arg, Fact_Arg, Current_Subs, New_Subs) :-
	var(BI_Arg),
	((
		get_sub(BI_Arg, Current_Subs, Sub)
	) -> (
		Sub == Fact_Arg,
		New_Subs = Current_Subs
	) ;	(
		New_Subs = [BI_Arg:Fact_Arg | Current_Subs]
	)).

get_sub(X, [(Y:S) | Subs], Sub) :-
	((
		X == Y
	) -> (
		Sub = S
	) ; (
		get_sub(X, Subs, Sub)
	)).

% we know we don't have to apply any new subs because we only
% succeed if the constraint is a ground term, but we need to be checking
% for ground and applying the constraints after substituting w/ the
% current subs
% since the constraint is a ground term we know that applying it won't have
% any effect
check_body_constraint(Constraint, Subs, Subs) :-
	debug((
		format("Check body constraint: ~w~n", [Constraint])
	), 3),
	copy_fact_with_subs2(Constraint, Subs, New_Constraint, _),
	ground(New_Constraint),
	{New_Constraint}.
	% to extend to constraints with variables, use:
	% \+({~New_Constraint}).
	% where ~ is the negation of New_Constraint, i.e. if the constraint is X < Y, use \+({X >= Y})
	% but note that this will only work on sets of constraints for which clpq is actually complete
	% in the sense of: if it's semantically true that a constraint X is false, then {X} will necessarily
	%  fail (as opposed to succeeding with variables because it can't determine that X is unsatisfiable)
	%  if we attempt to use this with sets of constraints for which clpq is not complete, then
	%  the reasoning would become unsound, i.e. we may derive something which is actually semantically false
	%  which would be bad

/*
 \+(({~B}, ground(B)))

 current constraint: X < 5
 rule body constraint: X >= 10
 X >= 10 is satisfied if X < 10 is unsatisfiable
 X < 10 is satisfiable if {X < 10} succeeds, assuming CLPQ is complete relative to any other constraints that X is involved in
so X < 10 is unsatisfiable if \+({X < 10}) succeeds

 \+(({X < 10}, ground(X < 10)))


 succeeds, consistent, bound      -> fails; correct
 succeeds, consistent, unbound    -> succeeds; incorrect and leads to inconsistency
 succeeds, inconsistent, unbound  -> succeeds; correct
 fails, inconsistent;             -> succeeds; correct

 \+(({~B}, \+ground(B)))
 succeeds, consistent, bound	  -> succeeds; incorrect and leads to inconsistency
 succeeds, consistent, unbound	  -> fails; correct
 succeeds, inconsistent, unbound  -> fails; incorrect but fine
 fails, inconsistent;			  -> succeeds; correct

 \+(({~B}, and_we_know_there_are_solutions_to({~B}))
 ground(~B) implements "and_we_know_there_are_solutions_to({~B})", with false negatives
 i.e. if ground(~B) succeeds, we know there are solutions to ~B; the \+ will then fail correctly
if ground(~B) fails, there might still be solutions to ~B; the \+ will then succeed, leading to incorrect behavior

we need the opposite, i.e. we have \+(({~B}, P)) where P is an approximation of "and_we_know_there_are_solutions_to({~B})", but
with at worst, false positives




*/


fact_sets_equal(A, B) :-
	fact_set_subset(A, B, []),
	fact_set_subset(B, A, []),
	!.

fact_set_subset([], _, _).
fact_set_subset([A | As], Bs, Current_Subs) :-
	fact_in(A, Bs, Current_Subs, New_Subs),
	fact_set_subset(As, Bs, New_Subs).

% _==_
% X = Y, X == Y; true...

fact_in(A, [B | Bs], Current_Subs, New_Subs) :-
	fact_match(A, B, Current_Subs, New_Subs) ;
	fact_in(A, Bs, Current_Subs, New_Subs).

fact_match(A, B, Current_Subs, New_Subs) :-
	A =.. [fact | A_Args],
	B =.. [fact | B_Args],
	fact_match_args(A_Args, B_Args, Current_Subs, New_Subs).

fact_match_args([], [], Subs, Subs).
fact_match_args([A_Arg | A_Args], [B_Arg | B_Args], Current_Subs, New_Subs) :-
	fact_match_arg(A_Arg, B_Arg, Current_Subs, Next_Subs),
	fact_match_args(A_Args, B_Args, Next_Subs, New_Subs).

/*
A = arg from body item
B = arg from fact
*/
fact_match_arg(A, B, Current_Subs, New_Subs) :-
	var(A),
	((
		% find existing substitution
		get_sub(A, Current_Subs, Sub)
	) -> (
		% not substituted to this? fail
		B == Sub,
		New_Subs = Current_Subs
	) ; (
		% cant bind a non-var? A
		var(B),
		% create new substitution
		New_Subs = [A:B | Current_Subs]
	)).

fact_match_arg(A, B, Subs, Subs) :-
	nonvar(A),
	A == B.



copy_facts_with_subs2([], Subs, [], Subs) :-
	debug((
		format("copy_facts_with_subs2: done~n",[])
	), 5).

copy_facts_with_subs2([Fact | Facts], Subs, [New_Fact | New_Facts], New_Subs) :-
	Fact = fact(_,_,_),
	debug((
		format("copy_facts_with_subs2: [~w | ~w ]~n",[Fact,Facts])
	),5),

	copy_fact_with_subs2(Fact, Subs, New_Fact, Next_Subs),
	copy_facts_with_subs2(Facts, Next_Subs, New_Facts, New_Subs).

% my next problem is making these equality/constraint assertions robust against when you feed an atom through it
copy_facts_with_subs2([Constraint | Facts], Subs, [New_Constraint | New_Facts], New_Subs) :-
	Constraint = (_ = _),
	debug((
		format("copy_facts_with_subs2: [~w | ~w]~n",[Constraint, Facts])
	), 5),
	copy_fact_with_subs2(Constraint, Subs, New_Constraint, Next_Subs),
	New_Constraint = (LHS = RHS),
	LHS = RHS,
	copy_facts_with_subs2(Facts, Next_Subs, New_Facts, New_Subs).

copy_facts_with_subs2([Constraint | Facts], Subs, [New_Constraint | New_Facts], New_Subs) :-
	Constraint \= fact(_,_,_),
	Constraint \= (_ = _),
	debug((
		format("copy_facts_with_subs2: [~w | ~w]~n",[Constraint, Facts])
	), 5),
	copy_fact_with_subs2(Constraint, Subs, New_Constraint, Next_Subs),
	((
		{New_Constraint}
	) -> (
		true
	) ; (
		format("Inconsistency error: ~w~n", [New_Constraint]),
		fail
	)),
	copy_facts_with_subs2(Facts, Next_Subs, New_Facts, New_Subs).

copy_fact_with_subs2(Fact, Subs, New_Fact, New_Subs) :-
	debug((
		format("copy_fact_with_subs2: ~w~n", [Fact])
	), 6),
	Fact =.. [F | Args],
	copy_args_with_subs2(Args, Subs, New_Args, New_Subs),
	New_Fact =.. [F | New_Args],
	debug((
		format("copy_fact_with_subs2 (done): ~w~n", [New_Fact])
	), 6).

copy_args_with_subs2([], Subs, [], Subs).
copy_args_with_subs2([Arg | Args], Subs, [New_Arg | New_Args], New_Subs) :-
	((
		var(Arg)
	) -> (
		copy_arg_with_subs2(Arg, Subs, New_Arg, Next_Subs),
		copy_args_with_subs2(Args, Next_Subs, New_Args, New_Subs)
	) ; (
		copy_fact_with_subs2(Arg, Subs, New_Arg, Next_Subs),
		copy_args_with_subs2(Args, Next_Subs, New_Args, New_Subs)
	)).

copy_arg_with_subs2(Arg, Subs, Arg, Subs) :- nonvar(Arg).
copy_arg_with_subs2(Arg, Subs, New_Arg, Subs) :- var(Arg), get_sub(Arg, Subs, New_Arg).
copy_arg_with_subs2(Arg, Subs, New_Arg, [Arg:New_Arg | Subs]) :- var(Arg), \+get_sub(Arg, Subs, New_Arg).



make_collect_facts_rules([], [], []).
make_collect_facts_rules([fact(S,P,O) | KB], [fact(S,P,O) | Facts], Rules) :-
	!,
	make_collect_facts_rules(KB, Facts, Rules).
make_collect_facts_rules([(Head :- Body) | KB], Facts, [Rule | Rules]) :-
	copy_term((Head :- Body), Rule),
	make_collect_facts_rules(KB, Facts, Rules).

% make_kb(Input_KB, Facts, Constraints, Fact_Generating_Rules, Constraint_Generating_Rules)
make_kb(Input, KB, Max_Depth) :-
	findall(
		Fact,
		(
			member(Fact, Input),
			Fact = fact(_,_,_)
		),
		Facts
	),
	findall(
		Constraint,
		(
			member(Constraint, Input),
			Constraint \= fact(_,_,_),
			Constraint \= (_ :- _)
		),
		Constraints
	),
	findall(
		Fact_Rule,
		(
			member(Fact_Rule0, Input),
			Fact_Rule0 = (_ :- _),
			get_fact_rule(Fact_Rule0, Fact_Rule) 
		),
		Fact_Rules
	),
	findall(
		Constraint_Rule,
		(
			member(Constraint_Rule0, Input),
			Constraint_Rule0 = (_ :- _),
			get_constraint_rule(Constraint_Rule0, Constraint_Rule)
		),
		Constraint_Rules
	),
	KB = kb{
		facts: Facts,
		constraints: Constraints,
		fact_rules: Fact_Rules,
		constraint_rules: Constraint_Rules,
		depth: 1,
		max_depth: Max_Depth
	}.

get_fact_rule(Head :- Body, [New_Head] :- Body) :-
	member(New_Head, Head),
	New_Head = fact(_,_,_).

get_constraint_rule(Head :- Body, [New_Head] :- Body) :-
	member(New_Head, Head),
	New_Head \= fact(_,_,_).

print_kb(KB) :-
	format("Facts: ~n", []),
	print_facts(KB.facts),
	nl,
	format("Constraints: ~n", []),
	print_constraints(KB.constraints),
	nl,
	format("Rules: ~n", []),
	print_rules(KB.fact_rules),
	print_rules(KB.constraint_rules).

chase_test1([
	fact(hp1, a, hp_arrangement),
	fact(hp1, cash_price, 50), % these would collapse to just fact(hp1, cash_price, 50)
	fact(hp1, cash_price, _), % if this was fact(hp1, cash_price, 100) we'd get inconsistency error

	% this looks like a functional dependency but it's actually a relation attribute declaration
	% an hp_arrangement has a cash_price and only one cash_price does this enforce "only one"?
	([fact(HP, cash_price, _)] :- [fact(HP, a, hp_arrangement)]),
	% processing this rule should enforce "only one" yea
	% any duplicates would be unified and collapsed into a single triple, when possible, otherwise
	% throw inconsistency error when {X = Y} can't be satisfied due to two different cash_price's
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price, Y)]),

%	([fact(HP, something, _)] :- []),
	([fact(HP, interest_rate, _)] :- [fact(HP, a, hp_arrangement)]),
	([fact(HP, begin_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([fact(HP, end_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([fact(HP, report_start_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([fact(HP, report_end_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([fact(HP, repayment_amount, _)] :- [fact(HP, a, hp_arrangement)]),
	([fact(HP, payment_type, _)] :- [fact(HP, a, hp_arrangement)])
]).

chase_test2([
	fact(a, b1, 5),
	fact(a, b2, What),
	([fact(a, b3, Zhat), (Zhat = What + That)] :- [fact(a, b1, That), fact(a, b2, What)])
]).

chase_test3([
	fact(a, b1, 5),
	fact(a, b2, _),
	([(X = Y)] :- [fact(A, b1, X), fact(A, b2, Y)])
]).

chase_test4([
	fact(a, b1, 5),
	fact(a, b1, _),
	([(X = Y)] :- [fact(A, b1, X), fact(A, b1, Y)])
]).

chase_test5([
	fact(X, b1, 5),
	fact(a, b1, 5),
	fact(a, b1, _),
	([(X = Y)] :- [fact(A, b1, X), fact(A, b1, Y)])
]).

chase_test6([
	fact(hp1, a, hp_arrangement),
	fact(hp1, cash_price, 50),
	fact(hp1, cash_price, _),
	([X = Y] :- [fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price, Y)])
]).

chase_test7([
	fact(hp1, a, hp_arrangement),
	fact(hp1, cash_price, 50),
	fact(hp1, cash_price, _),
	([fact(HP, cash_price, _)] :- [fact(HP, a, hp_arrangement)]),
	([X = Y] :- [fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price, Y)])
]).

chase_test8([
	fact(hp1, a, hp_arrangement),
	fact(hp1, cash_price, 50), % these would collapse to just fact(hp1, cash_price, 50)
	fact(hp1, cash_price, _), % if this was fact(hp1, cash_price, 100) we'd get inconsistency error

	% this looks like a functional dependency but it's actually a relation attribute declaration
	% an hp_arrangement has a cash_price and only one cash_price does this enforce "only one"?
	([fact(HP, cash_price, _)] :- [fact(HP, a, hp_arrangement)]),
	% processing this rule should enforce "only one" yea
	% any duplicates would be unified and collapsed into a single triple, when possible, otherwise
	% throw inconsistency error when {X = Y} can't be satisfied due to two different cash_price's
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price, Y)]),

	% 
	([fact(HP, interest_rate, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, interest_rate, X), fact(HP, interest_rate, Y)]),

	([fact(HP, begin_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, begin_date, X), fact(HP, begin_date, Y)]),

	([fact(HP, end_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, end_date, X), fact(HP, end_date, Y)]),

	([fact(HP, report_start_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, report_start_date, X), fact(HP, report_start_date, Y)]),

	([fact(HP, report_end_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, report_end_date, X), fact(HP, report_end_date, Y)]),

	([fact(HP, repayment_amount, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, repayment_amount, X), fact(HP, repayment_amount, Y)]),

	([fact(HP, payment_type, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, payment_type, X), fact(HP, payment_type, Y)])
]).

chase_test9([
	fact(hp1, a, hp_arrangement),
	fact(hp1, cash_price, _),
	([fact(HP, cash_price, _)] :- [fact(HP, a, hp_arrangement)]),
	([X = Y] :- [fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price, Y)])
]).

chase_test10([
	fact(hp1, a, hp_arrangement),
	fact(hp1, cash_price, 50),
	fact(hp1, cash_price2, _),
	([X = (Y + 5)] :- [fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price2, Y)])
	
]).

chase_test11([
	fact(hp1, a, hp_arrangement),

	% generalize this object/relation declaration
	([fact(HP, cash_price, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price, Y)]),

	([fact(HP, interest_rate, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, interest_rate, X), fact(HP, interest_rate, Y)]),

	([fact(HP, begin_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, begin_date, X), fact(HP, begin_date, Y)]),

	([fact(HP, end_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, end_date, X), fact(HP, end_date, Y)]),

	([fact(HP, report_start_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, report_start_date, X), fact(HP, report_start_date, Y)]),

	([fact(HP, report_end_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, report_end_date, X), fact(HP, report_end_date, Y)]),

	([fact(HP, repayment_amount, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, repayment_amount, X), fact(HP, repayment_amount, Y)]),

	([fact(HP, payment_type, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, payment_type, X), fact(HP, payment_type, Y)]),

	([fact(HP, number_of_installments, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, number_of_installments, X), fact(HP, number_of_installments, Y)]),

	([fact(HP, installments, Installments), fact(Installments, a, list)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, installments, X), fact(HP, installments, Y)])

]).

/*
% something is a  list
% that list has length N
% something is in the list
% the list has a first (if it's non-empty)
% the list has a last (if it's non-empty)

% i don't necessarily know how to implement "we *know* its not the last element" (or w/e) 
nonvar(a) && nonvar(b) && a \== b
wouldnt list bnodes normally be vars?
this is an older comment


for any list item, if it's not the last, there's a next;
	if it's not the first, there's a previous

fact(I, prev, P) :- 
	I list_in L,
	I list_index \= 1

	L first PP
	I \= PP,


5 + 10 = 15.1
5 USD + 10 USD = 15.1 USD
5 days * (10 USD / day) = 50 USD

*/

/*

	Item,	value, V 
	&		list_in L
	&		index I
<= 
	Item a list_item
|

X list_in L <=> L a list, X a list_item.
% this doesn't work cause X a list_item doesn't indicate that X is a list_item *of* L
% it might indicate that it's in *some* list, but we don't know that that list is L


% this is logically sound: if we know X is a list item then we know it's in *Some* list,
%  we just don't know which list.
% but suggests that "list_item" as a type doesn't have much
% utility, or at least, I haven't yet encountered a case where we want to say that X
% is a list item without any indication of which list it's in so having just "list_in"
% seems sufficient
X list_in L. L a list <=> X a list_item.

% this might even work:
X list_in L <=> X a list_item
X list_in L => L a list
X list_in L. L element_type T => X a T


===


nil a list

L a list, L first F, L rest R <= R a list

% so the representation i used ended up being almost the same as this
% lists in RDF representation = list-cells/positions in my representation
%  value = first
%  next  = rest

% list-cells/positions in my representation have two extra attributes:
%  list_index
%  prev

% can uniquely have next in RDF representation but it allows (perhaps even expects?) multiple prev's

well multiple nexts or prevs are fine/expected during reasoning at least, i'd say
well there's a semantic difference between "there's multiple possibilities cause we don't know which *one* it is yet" and
"there can actually be multiple distinct ones simultaneously"
okay, lists with multiple beginnings are prefectly valid for all purposes i think. if we end up with multiple tails, 
that's not a valid rdf list or whatever but yea..

% my representation has an extra node to represent the whole list
whats the extra node?

% in RDF representation we say that "value list_in list_cell"
% bn0a first a.
% bn0a rest bn1.
% bn0b first b.
% bn0b rest bn1.
% bn1 first x    % what should be the previous element of bn1?

% bn1 rest bn2
% bn2 first y
% bn2 rest nil.
% we say that x and y list_in bn1

% in my representation list_in actually applies to the list cells and relates them to the extra list bnode
% there should still be an equivalent of RDF's list_in ofc

% RDF list-cells don't uniquely have a position (as measured from the start of the list; they do have a position
% as measured from the end of the list; this is a consequence of the fact that "rest" is unique but there is no
% unique "prev", and because list-cells are lists, this means a list-cell isn't uniquely in any particular list)

well i've been wondering if we want to actually allow for multiple "pos" objects, relating a cell to some head cell and an index.
also, in pyco, if i wanted to express an integer distance between two cells, 
i could "simply" say <uniquely identified head> rest ?x, ?x rest ?y, ?y rest ........... <this cell>
so, idk, maybe we want to express some equivalence between these two encodings..
well the above only works when you already know the distance and it's not a variable that you're still solving for
but generally i'd agree if we end up actually using a different representation (of any two things, generally) we'd want some stuff to 
translate or rather allow to just use either one interchangeably or even mixed in the same kb (if the translation is direct enough, like it is
in this case)
i guess i was just wondering if these two representations are equvalent, and i guess thats kinda answered now..
except, i still dont have a grasp on shy..
can we do that:
?H rest ?X. ?X rest ?This <= ?This is_two_cells_after ?H
 * sure you could do that w/ this rule
 * i'll think about whether you could do it currently in terms of constraints on the position integers


?H = ?C <= ?P a pos, ?p index 0, ?p has_head ?H, ?p has_cell ?C.

?P a pos, ?p index ?I2, {?I2 = I1 + 1} , ?p has_head ?H, ?p has_cell ?This

ah, no there's probably no way to currently correctly generate all the elements in between just from the
integers due to not being able to use constraints in rule-bodies, or at least, i haven't figured out a
way around that yet really except in some special cases, not sure if this is one

the way you would write this probably in current rule-set would be
bn1 a diff
bn1 in1 ?H
bn1 in2 ?This
bn1 out1 ?N

{Out = In1 - In2} <= {D a diff. D in1 In1. D in2 In2. D out1 Out}
{X next Y. Y prev X} 	<= {L a list. X list_in L. X list_index In1. Y list_in L. Y list_index In2. D a diff. D in1 In1. D in2 In2. D out1 1}
{X = Y} 				<= {L a list. X list_in L. X list_index In1. Y list_in L. Y list_index In2. D a diff. D in1 In1. D in2 In2. D out1 0}
{Y next X. X prev Y} 	<= {L a list. X list_in L. X list_index In1. Y list_in L. Y list_index In2. D a diff. D in1 In1. D in2 In2. D out1 -1}


% i don't have an equivalent of rdf:nil in my representation
% in my representation the end of a list is the cell who's position (measured from the start of the list, ofc) is the length of the list

===

% this starts to get closer to the representation i came up w/ i.e. there's a distinction between cells/positions and the
% lists that they occur in

% this is probably only true if L is non-empty
L has_position P, P a position <= L a list
L has_position P

P a position => L has_index I, L has_list L, 

P a position, L a list <=> P is_relative_to L
% this says that all positions are relative to all lists
*/


list_theory([
	% every list item has a value, and only one value
	([fact(Item, value, _)] :- [fact(L, a, list), fact(Item, list_in, L)]),
	([V1 = V2] :- [fact(L, a, list), fact(X, list_in, L), fact(X, value, V1), fact(X, value, V2)]),

	% every list item belongs to only one list
	([L1 = L2] :- [fact(X, list_in, L1), fact(X, list_in, L2)]),

	% could also assert that the value has to be of a particular type
	([fact(V, a, T)] :- [fact(L, a, list), fact(X, list_in, L), fact(X, value, V), fact(L, element_type, T)]),

	% every list item has an index
	([fact(Item, list_index, _)] :- [fact(L, a, list), fact(Item, list_in, L)]),
	% a list item can only have one index
	([I1 =:= I2] :- [fact(L, a, list), fact(X, list_in, L), fact(X, list_index, I1), fact(X, list_index, I2)]),
	% there can only be one list item at any given index
	([X1 = X2] :- [fact(L, a, list), fact(X1, list_in, L), fact(X1, list_index, I), fact(X2, list_in, L), fact(X2, list_index, I)]),

	% could also assert that the index is greater than or equal to 1, and less than or equal to the length of the list
	% but i'm not sure whether these constraints actually give us anything or if they're just redundant (assuming other
	% axioms that do give us a full theory of lists)
	([I >= 1] :- [fact(L, a, list), fact(X, list_in, L), fact(X, list_index, I)]),
	([I =< N] :- [fact(L, a, list), fact(X, list_in, L), fact(X, list_index, I), fact(L, length, N)]),

	% if the list is non-empty then it has a first and a last
	% a list can only have one first and one last
	([fact(L, first, _)] :- [fact(L, a, list), fact(_, list_in, L)]),
	([X = Y] :- [fact(L, a, list), fact(L, first, X), fact(L, first, Y)]),

	([fact(L, last, _)] :- [fact(L, a, list), fact(_, list_in, L)]),
	([X = Y] :- [fact(L, a, list), fact(L, last, X), fact(L, last, Y)]),

	% if the list has first and last elements, then they're in the list
	% the index of the first element is 1, the index of the last element is the length of the list
	([fact(First, list_in, L), fact(First, list_index, 1)] :- [fact(L, a, list), fact(L, first, First)]),
	([fact(Last, list_in, L), fact(Last, list_index, N)] :- [fact(L, a, list), fact(L, last, Last), fact(L, length, N)]), % if N != 0 but.. 

	% every list has a length; a list can only have one length; if there's a last element, then the length of the
	% list is the index (starting from 1) of the last element
	([fact(L, length, N)] :- [fact(L, a, list)]),
	([L1 =:= L2] :- [fact(L, a, list), fact(L, length, L1), fact(L, length, L2)]),

	([fact(L, length, N)] :- [fact(L, a, list), fact(L, last, Last), fact(Last, list_index, N)]),

	% relationship between previous and next
	([fact(Y, prev, X)] :- [fact(X, next, Y)]),
	([fact(X, next, Y)] :- [fact(Y, prev, X)]),
	([X1 = X2] :- [fact(Y, prev, X1), fact(Y, prev, X2)]),
	([Y1 = Y2] :- [fact(X, next, Y1), fact(X, next, Y2)]),
	([fact(L, a, list), fact(X, list_in, L), fact(Y, list_in, L)] :- [fact(X, next, Y)]),
	

	([fact(Y, list_index, N), (N =:= (M + 1))] :- [fact(L, a, list), fact(X, list_in, L), fact(X, next, Y), fact(X, list_index, M)]),
	([fact(X, list_index, M), (N =:= (M + 1))] :- [fact(L, a, list), fact(Y, list_in, L), fact(Y, prev, X), fact(Y, list_index, N)])

	% if a list item is not the first element (equivalently if it's index is greater than 1), then there's a previous element
	% if a list item is not the last element (equivalently if its index is less than the lenght of the list), then there's a next element
	% for every index greater than 1 and less than the length of the list, there is a list item at that index
]).

relation_theory([
	([fact(O, A, _)] :- [fact(R, a, relation), fact(O, a, R), fact(R, attribute, A)]),
	([(X = Y)] :- [fact(O, a, R), fact(R, attribute, A), fact(O, A, X), fact(O, A, Y)])
]).

nat_theory([
	fact(0, a, nat),
	([fact(X, suc, SX), fact(SX, a, nat)] :- [fact(X, a, nat)]),
	([Y = Z] :- [fact(X, a, nat), fact(X, suc, Y), fact(X, suc, Z)])
]).

/*
hp_base_theory([
	% using list theory
	([fact(HP, cash_price, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price, Y)]),

	([fact(HP, interest_rate, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, interest_rate, X), fact(HP, interest_rate, Y)]),

	([fact(HP, begin_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, begin_date, X), fact(HP, begin_date, Y)]),

	([fact(HP, end_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, end_date, X), fact(HP, end_date, Y)]),

	([fact(HP, report_start_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, report_start_date, X), fact(HP, report_start_date, Y)]),

	([fact(HP, report_end_date, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, report_end_date, X), fact(HP, report_end_date, Y)]),

	([fact(HP, repayment_amount, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, repayment_amount, X), fact(HP, repayment_amount, Y)]),

	([fact(HP, payment_type, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, payment_type, X), fact(HP, payment_type, Y)]),

	([fact(HP, number_of_installments, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, number_of_installments, X), fact(HP, number_of_installments, Y)]),

	([fact(HP, installments, Installments), fact(Installments, a, list), fact(Installments, element_type, hp_installment)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, installments, X), fact(HP, installments, Y)]),
	
	([fact(HP, remainder, _)] :- [fact(HP, a, hp_arrangement)]),
	([(X = Y)] :- [fact(HP, a, hp_arrangement), fact(HP, remainder, X), fact(HP, remainder, Y)]),

	
	([fact(Installment, opening_balance, _)] :- [fact(Installment, a, hp_installment)]),
	([(X = Y)] :- [fact(Installment, a, hp_installment), fact(Installment, opening_balance, X), fact(Installment, opening_balance, Y)]),

	([fact(Installment, closing_balance, _)] :- [fact(Installment, a, hp_installment)]),

	([fact(Installment, 
	

	([fact(First_Installment, opening_balance, Cash_Price)] :- [fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(Installments, first, First_Installment), fact(HP, cash_price, Cash_Price)]),
	([fact(HP, cash_price, Cash_Price)] :- [fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(Installments, first, First_Installment), fact(First_Installment, opening_balance, Cash_Price)]),

	([fact(HP, remainder, Remainder)] :- [fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(Installments, last, Last_Installment), fact(Last_Installment, closing_balance, Remainder)]),
	([fact(Last_Installment, closing_balance, Remainder)] :- [fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(Installments, last, Last_Installment), fact(Last_Installment, closing_balance, Remainder)]),
	(
	
]).
*/



list_test1([
	fact(my_list, a, list),

	% "list_in" w/ direct values for subject doesn't support the notion of multiple distinct occurrences
	fact(A, list_in, my_list), % the list is non-empty
	fact(B, list_in, my_list),
	fact(A, next, B),
	fact(my_list, first, A),
	fact(my_list, last, B)
]).

relation_test1([
	fact(hp_arrangement, a, relation),

	% attributes should have types
	fact(hp_arrangement, attribute, cash_price),
	fact(hp_arrangement, attribute, begin_date),
	fact(hp_arrangement, attribute, end_date),
	fact(hp_arrangement, attribute, interest_rate),
	fact(hp_arrangement, attribute, repayment_amount),
	fact(hp_arrangement, attribute, repayment_period),
	fact(hp_arrangement, attribute, number_of_installments),
	fact(hp_arrangement, attribute, installments),
	fact(hp_arrangement, attribute, total_payments),
	fact(hp_arrangement, attribute, total_interest),

	fact(hp_installment, a, relation),
	fact(hp_installment, attribute, hp_arrangement),
	fact(hp_installment, attribute, opening_date),
	fact(hp_installment, attribute, opening_balance),
	fact(hp_installment, attribute, payment_type),
	fact(hp_installment, attribute, payment_amount),
	fact(hp_installment, attribute, interest_amount),
	fact(hp_installment, attribute, interest_rate),
	fact(hp_installment, attribute, closing_date),
	fact(hp_installment, attribute, closing_balance),

	([fact(Installments, a, list), fact(Installments, element_type, hp_installment)] :- [fact(HP, a, hp_arrangement), fact(HP, installments, Installments)]),
	([fact(Installment, hp_arrangement, HP)] :- [fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(Index, list_in, Installments), fact(Index, value, Installment)]),


	([(Payment_Amount =:= Repayment_Amount)] :- [fact(I, a, hp_installment), fact(I, hp_arrangement, HP), fact(HP, repayment_amount, Repayment_Amount), fact(I, payment_amount, Payment_Amount), fact(I, payment_type, regular)]),
	([fact(I, payment_type, regular)] :- [fact(I, a, hp_installment), fact(I, hp_arrangement, HP), fact(HP, repayment_amount, Repayment_Amount), fact(I, payment_amount, Repayment_Amount), fact(I, payment_type, regular)]),

	([((Interest_Amount / Interest_Rate) =:= Opening_Balance)] :- [fact(I, a, hp_installment), fact(I, interest_rate, Interest_Rate), fact(I, interest_amount, Interest_Amount), fact(I, opening_balance, Opening_Balance)]),

	([(Closing_Balance =:= Opening_Balance + Interest_Amount - Payment_Amount)] :- [fact(I, a, hp_installment), fact(I, closing_balance, Closing_Balance), fact(I, opening_balance, Opening_Balance), fact(I, interest_amount, Interest_Amount), fact(I, payment_amount, Payment_Amount)]),


	% continuity principle that facilitate transfer of balances between successive closing & opening balances
	([(Closing_Prev =:= Opening_Next)] :- [fact(Prev, a, hp_installment), fact(Prev, next, Next), fact(Prev, closing_balance, Closing_Prev), fact(Next, opening_balance, Opening_Next)]),

	([(Opening_Next =:= Closing_Prev + 1)] :- [fact(Prev, a, hp_installment), fact(Prev, next, Next), fact(Prev, closing_date, Closing_Prev), fact(Next, opening_date, Opening_Next)]),

	([(Interest_Rate =:= Installment_Rate)] :- [fact(HP, a, hp_arrangement), fact(Installment, hp_arrangement, HP), fact(HP, interest_rate, Interest_Rate), fact(Installment, interest_rate, Installment_Rate)]),

	([fact(Installment, next, Next), fact(Next, a, hp_installment), fact(Next, hp_arrangement, HP), fact(Next, payment_type, regular)] :- [fact(HP, a, hp_arrangement), fact(HP, repayment_amount, R), fact(Installment, a, hp_installment), fact(Installment, hp_arrangement, HP), fact(Installment, closing_balance, C), (C >= R)]),


	fact(hp1, a, hp_arrangement),
	fact(hp1, cash_price, 500),
	fact(hp1, repayment_amount, 50),
	fact(hp1, installments, Installments),
	fact(hp1, interest_rate, 0.13),

	fact(Installment, list_in, Installments),
	fact(Installment, value, in1),
	fact(in1, a, hp_installment),
	fact(in1, hp_arrangement, hp1),
	fact(in1, opening_balance, 100),
	fact(in1, payment_type, regular)
]).

body_constraints_test1([
	fact(a, b, 50),
	([(Z =:= X - 25), fact(a, b, Z)] :- [fact(a, b, X), (X >= 25)])
]).

/*
Continuous curve theory
*/



sets_equal(R, S1, S2) :-
	subset(R, S1, S2),
	subset(R, S2, S1).

subset(R, S1, S2) :-
	\+((
		member(X,S1),
		\+((
			member(Y,S2),
			call(R, X, Y)
		))
	)).

in_set(R, S, X) :-
	member(Y, S),
	call(R, X, Y),
	!.

to_set(R, L, S) :-
	to_set_helper(R, L, [], S).

to_set_helper(_, [], S, S).
to_set_helper(R, [X | Xs], S_Acc, S) :-
	\+in_set(R, S_Acc, X) ->
	to_set_helper(R, Xs, [X | S_Acc], S) ;
	to_set_helper(R, Xs, S_Acc, S).


print_facts([]).
print_facts([fact(S, P, O) | Facts]) :-
	format("~w ~w ~w~n", [S, P, O]),
	print_facts(Facts).

print_constraints([]) :- nl.
print_constraints([Constraint | Constraints]) :-
	((
		\+((Constraint = (X = Y), X == Y)),
		\+((Constraint = (X =:= Y), X == Y))
	) -> (
		format("~w~n", [Constraint])
	) ; (
		true
	)),
	print_constraints(Constraints).


print_rules(Rules) :-
	foreach(member(R, Rules), (
		writeq(R),
		nl)).


/*
=/2
==/2
*/


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

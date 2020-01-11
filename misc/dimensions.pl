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




/*
Chase
*/
chase(KB, Results, Max_Depth) :-
	%make_kb(KB, Facts, Rules, Rule_Vars, Vars),
	%format("kb facts: ~w~n", [Facts]),
	%format("kb vars: ~w~n",[Vars]),
	make_collect_facts_rules(KB, Facts, Rules),
	chase_rules(Facts, Rules, Results, 1, N, Max_Depth),
	format("~nChase finished after ~w rounds:~n", [N]),
	print_facts(Results), nl.

chase_rules(Facts, Rules, New_Facts, Depth, N, Max_Depth) :-
	format("~nChase round: ~w~n", [Depth]),
	format("Facts: ~w~n", [Facts]),
	copy_term(Facts, Original_Facts),
	chase_round(Facts, Rules, Next_Facts),
	format("Done chase round: ~w~n", [Next_Facts]),
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
		 \+(fact_sets_equal(Original_Facts, Next_Facts)),
		 Depth < Max_Depth
		)
	-> 	(
		 %format("Success branch...~n", []),
		 Next_Depth is Depth + 1,
		 chase_rules(Next_Facts, Rules, New_Facts, Next_Depth, N, Max_Depth)
		)
	;	(
		 %format("Fail branch...~n", []),
		 New_Facts = Next_Facts,
		 N = Depth
		)
	).


chase_round(Facts, [], Facts).
chase_round(Facts, [Rule | Rules], New_Facts) :-
	chase_rule(Facts, Rule, Heads_Nested),
	flatten(Heads_Nested, Heads),
	%chase_head_facts(Heads, Head_Facts),
	%chase_head_constraints(Heads, Head_Constraints),
	append(Facts, Heads, Next_Facts_List),
	%format("Next facts list (before constraints): ~w~n", [Next_Facts_List]),
	%chase_apply_constraints(Head_Constraints),
	%format("Next facts list (after constraints): ~w~n", [Next_Facts_List]),

	to_set('==', Next_Facts_List, Next_Facts),
	%format("Next facts: ~w~n", [Next_Facts]),

	chase_round(Next_Facts, Rules, New_Facts).

chase_head_facts([], []).
chase_head_facts([Head|Heads], [Head|Head_Facts]) :- Head = fact(_,_,_), chase_head_facts(Heads, Head_Facts).
chase_head_facts([Head|Heads], Facts) :- Head \= fact(_,_,_), chase_head_facts(Heads, Facts).

chase_head_constraints([], []).
chase_head_constraints([Head|Heads], [Head|Head_Constraints]) :- Head \= fact(_,_,_), chase_head_constraints(Heads, Head_Constraints).
chase_head_constraints([Head|Heads], Constraints) :- Head = fact(_,_,_), chase_head_constraints(Heads, Constraints).

chase_apply_constraints([]).
chase_apply_constraints([Constraint | Rest]) :- 
	format("Applying constraint: ~w~n", [Constraint]),
	{Constraint},
	format("Constraint after applied: ~w~n", [Constraint]),
	chase_apply_constraints(Rest).

% match the rule against the fact-set treating distinct variables in the fact-set as distinct fresh constants
% when asserting the head constraints, treat any variables bound from the fact-set as actual variables
chase_rule(Facts, Rule, Heads) :-
	Rule = (_ :- Body),
	chase_rule_helper2(Facts, Rule, Body, Facts, [], [], Heads).

% if we match all the body items, succeed
chase_rule_helper2(_, Rule, [], _, Current_Subs, Current_Heads, [New_Head | Current_Heads]) :-
	Rule = (Head :- _),

	%existential vars will be fresh; universal vars will be bound with the same bindings as found in the body
	copy_facts_with_subs2(Head, Current_Subs, New_Head, _).


% we've tried one body item against all the facts
chase_rule_helper2(_, _, _, [], _, Current_Heads, Current_Heads).

% still more facts, still more body items
chase_rule_helper2(Facts, Rule, [Body_Item|Rest], [Fact | Rest_Facts], Current_Subs, Current_Heads, New_Heads) :-
	%format("rule: ~w~nbody item: ~w~nfact: ~w~nsubs: ~w~n",[Rule, Body_Item, Fact, Current_Subs]),
	%copy_with_subs(Body_Item, Vars, Current_Subs, BI_Copy, New_Subs),
	%format("body item (with vars): ~w~n", [BI_Copy]),
	(	
		(
			match_fact(Body_Item, Fact, Current_Subs, New_Subs)
		)
	-> 	(
			% body item match, recurse over rest of body
			%append(Current_Matches, [Fact], Next_Matches),
			chase_rule_helper2(Facts, Rule, Rest, Facts, New_Subs, Current_Heads, Next_Heads)
		)
	; 	(
			% no match, no updates
			Next_Heads = Current_Heads
		)
	),
	% recurse over rest of facts, repeating the same body item
	chase_rule_helper2(Facts, Rule, [Body_Item|Rest], Rest_Facts, Current_Subs, Next_Heads, New_Heads).



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
	(	get_sub(BI_Arg, Current_Subs, Sub)
	-> 	(
			Sub == Fact_Arg,
			New_Subs = Current_Subs
		)
	;	(
			New_Subs = [BI_Arg:Fact_Arg | Current_Subs]
		)
	).

get_sub(X, [(Y:S) | Subs], Sub) :-
	(
		X == Y
	) -> (
		Sub = S
	) ; (
		get_sub(X, Subs, Sub)
	).



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
	(
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
	).

fact_match_arg(A, B, Subs, Subs) :-
	nonvar(A),
	A == B.



copy_facts_with_subs2([], Subs, [], Subs).
copy_facts_with_subs2([Fact | Facts], Subs, [New_Fact | New_Facts], New_Subs) :-
	Fact = fact(_,_,_),
	copy_fact_with_subs2(Fact, Subs, New_Fact, Next_Subs),
	copy_facts_with_subs2(Facts, Next_Subs, New_Facts, New_Subs).

copy_facts_with_subs2([Constraint | Facts], Subs, New_Facts, New_Subs) :-
	Constraint \= fact(_,_,_),
	copy_fact_with_subs2(Constraint, Subs, New_Constraint, Next_Subs),
	%pattern match against substituted head fact
	New_Constraint = (LHS = RHS),
	var(LHS), var(RHS),
	% collapse two existentials
	LHS = RHS, % if we put this in {}/1 then it won't unify LHS and RHS
	copy_facts_with_subs2(Facts, Next_Subs, New_Facts, New_Subs).

copy_facts_with_subs2([Constraint | Facts], Subs, New_Facts, New_Sub) :-
	Constraint \= fact(_,_,_),
	copy_fact_with_subs2(Constraint, Subs, New_Constraint, Next_Subs),
	New_Constraint = (LHS = RHS),
	\+((var(LHS), var(RHS))), % LHS = (Y + 5) or 50 = RHS or 50 = 50 
	{LHS = RHS},
	/*HS_Fresh = LHS},
	{RHS_Fresh = RHS},
	LHS_Fresh = RHS_Fresh, % 50 = (Y + 5) *NOT* equivalent to {50 = Y +5}, despite what the docs say
	*/
	copy_facts_with_subs2(Facts, Next_Subs, New_Facts, New_Subs).

copy_facts_with_subs2([Constraint | Facts], Subs, New_Facts, New_Subs) :-
	Constraint \= fact(_,_,_),
	copy_fact_with_subs2(Constraint, Subs, New_Constraint, Next_Subs),
	New_Constraint \= (_ = _),
	{New_Constraint},
	copy_facts_with_subs2(Facts, Next_Subs, New_Facts, New_Subs).

copy_fact_with_subs2(Fact, Subs, New_Fact, New_Subs) :-
	Fact =.. [F | Args],
	copy_args_with_subs2(Args, Subs, New_Args, New_Subs),
	New_Fact =.. [F | New_Args].

copy_args_with_subs2([], Subs, [], Subs).
copy_args_with_subs2([Arg | Args], Subs, [New_Arg | New_Args], New_Subs) :-
	(
		var(Arg)
	) -> (
		copy_arg_with_subs2(Arg, Subs, New_Arg, Next_Subs),
		copy_args_with_subs2(Args, Next_Subs, New_Args, New_Subs)
	) ; (
		copy_fact_with_subs2(Arg, Subs, New_Arg, Next_Subs),
		copy_args_with_subs2(Args, Next_Subs, New_Args, New_Subs)
	).

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
something is a  list
that list has length N
something is in the list
the list has a first (if it's non-empty)
the list has a last (if it's non-empty)

% i don't necessarily know how to implement "we *know* its not the last element" (or w/e) 
nonvar(a) && nonvar(b) && a \== b

for any list item, if it's not the last, there's a next;
	if it's not the first, there's a previous

fact(I, prev, P) :- 
	I list_in L,
	I list_index \= 1

	L first PP
	I \= PP,
	
*/

chase_test12([
	fact(my_list, a, list),

	% "list_in" w/ direct values for subject doesn't support the notion of multiple distinct occurrences
	fact(_, list_in, my_list), % the list is non-empty

	% if the list is non-empty then it has a first and a last
	([fact(L, first, First)] :- [fact(L, a, list), fact(_, list_in, L)]),
	([fact(L, last, Last)] :- [fact(L, a, list), fact(_, list_in, L)]),
/*
n-ary syntax: position(I,L,N)
triple syntax:
	% I is_item_in_position P
	% L is_list_for_position P
	% N is_index_of_position P
*/

	% "list_index"; if we use direct values, X list_index 1 doesn't tell us what list that X is in
	([fact(First, list_in, L), fact(First, list_index, 1)] :- [fact(L, a, list), fact(L, first, First)]),

	([fact(Last, list_in, L), fact(Last, list_index, N)] :- [fact(L, a, list), fact(L, length, N)]), % if N != 0 but.. 

	([fact(L, length, N)] :- [fact(L, a, list), fact(L, last, Last), fact(Last, list_index, N)]),

	([X = Y] :- [fact(L, a, list), fact(X, list_in, L), fact(
/*last_item
first_item
rest list
next item
prev item

*/
]).



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

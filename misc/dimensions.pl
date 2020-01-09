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
	make_kb(KB, Facts, Rules, Vars),
	format("kb facts: ~w~n", [Facts]),
	format("kb vars: ~w~n",[Vars]),
	chase_rules(Facts, Rules, Vars, New_Facts, New_Vars, 1, Max_Depth),
	copy_list_with_subs(New_Facts, New_Vars, _{}, Results, _),
	format("Chase finished: ~w~n", [Results]).

chase_rules(Facts, Rules, Vars, New_Facts, New_Vars, Depth, Max_Depth) :-
	format("Chase round: ~w~n", [Depth]),
	chase_round(Facts, Vars, Next_Vars, Rules, Next_Facts),
	format("Done chase round: ~w~n", [Next_Facts]),
	(
		(
		 % chase should stop when there's not enough information to determine that the new set of facts is not
		 % equivalent to the previous set of facts
		 \+(sets_equal('==',Facts, Next_Facts)),
		 Depth < Max_Depth
		)
	-> 	(
		 format("Success branch...~n", []),
		 Next_Depth is Depth + 1,
		 chase_rules(Next_Facts, Rules, Next_Vars, New_Facts, New_Vars, Next_Depth, Max_Depth)
		)
	;	(
		 format("Fail branch...~n", []),
		 New_Facts = Next_Facts,
		 New_Vars = Next_Vars
		)
	).


chase_round(Facts, Vars, Vars, [], Facts).
chase_round(Facts, Vars, New_Vars, [Rule | Rules], New_Facts) :-
	format("Applying rule: ~w~n", [Rule]),
	chase_rule(Facts, Vars, Next_Vars1, Rule, Heads_Nested),
	format("Heads_Nested = ~w~n", [Heads_Nested]),
	format("Next_Vars1 = ~w~n", [Next_Vars1]),
	flatten(Heads_Nested, Heads),
	chase_head_facts(Heads, Head_Facts),
	chase_head_constraints(Heads, Head_Constraints),
	format("Head facts: ~w~n", [Head_Facts]),
	format("Head constraints: ~w~n", [Head_Constraints]),
	append(Facts, Head_Facts, Next_Facts_List),
	copy_list_with_subs(Next_Facts_List, Next_Vars1, Next_Vars1, Next_Facts_List2, _),
	format("Next facts list (before constraints): ~w~n", [Next_Facts_List2]),
	copy_list_with_subs(Head_Constraints, Next_Vars1, Next_Vars1, Head_Constraints_Vars, _),
	format("Head constraints with vars: ~w~n", [Head_Constraints_Vars]),
	chase_apply_constraints(Head_Constraints_Vars),
	format("Next facts list (after constraints): ~w~n", [Next_Facts_List2]),
	to_set('==', Next_Facts_List2, Next_Facts),
	format("Next facts set: ~w~n", [Next_Facts]),
	make_list(Next_Facts, _{}, Next_Facts2, Next_Vars2),
	format("Next facts set: ~w~n", [Next_Facts]),
	chase_round(Next_Facts2, Next_Vars2, New_Vars, Rules, New_Facts).

chase_head_facts([], []).
chase_head_facts([Head|Heads], [Head|Head_Facts]) :- Head = fact(_,_,_), chase_head_facts(Heads, Head_Facts).
chase_head_facts([Head|Heads], Facts) :- Head \= fact(_,_,_), chase_head_facts(Heads, Facts).

chase_head_constraints([], []).
chase_head_constraints([Head|Heads], [Head|Head_Constraints]) :- Head \= fact(_,_,_), chase_head_constraints(Heads, Head_Constraints).
chase_head_constraints([Head|Heads], Constraints) :- Head = fact(_,_,_), chase_head_constraints(Heads, Constraints).

chase_apply_constraints([]).
chase_apply_constraints([Constraint | Rest]) :- 
	format("applying constraint: ~w~n", [Constraint]),
	{Constraint},
	chase_apply_constraints(Rest).

% match the rule against the fact-set treating distinct variables in the fact-set as distinct fresh constants
% when asserting the head constraints, treat any variables bound from the fact-set as actual variables
chase_rule(Facts, Vars, New_Vars, Rule, Heads) :-
	Rule = (_ :- Body),
	chase_rule_helper2(Facts, Vars, New_Vars, Rule, Body, Facts, _{}, [], Heads).

% if we match all the body items, succeed
chase_rule_helper2(_, Vars, New_Vars, Rule, [], _, Current_Subs, Current_Heads, [New_Head | Current_Heads]) :-
	format("rule: ~w~nsubs: ~w~n",[Rule, Current_Subs]),
	Rule = (Head :- _),
	%existential vars will be fresh; universal vars will be bound with the same bindings as found in the body
	copy_list_with_subs(Head, Vars, Current_Subs, Head1, _),
	make_list(Head1, Vars, New_Head, New_Vars).

% if we exhaust all facts for a body item then we're done with this branch
chase_rule_helper2(_, Vars, Vars, _, _, [], _, Current_Heads, Current_Heads).
chase_rule_helper2(Facts, Vars, New_Vars, Rule, [Body_Item|Rest], [Fact | Rest_Facts], Current_Subs, Current_Heads, New_Heads) :-
	format("rule: ~w~nbody item: ~w~nfact: ~w~n",[Rule, Body_Item, Fact]),
	% all bnodes representing vars will be substituted with actual vars
	% if those vars appeared in previous body items, then an association between the bnode and var/value should be
	% in Current_Subs, and we use that for the substitution
	% otherwise, we substitute with a fresh variable and append an association between the bnode and the fresh var into Current_Subs
	% to get New_Subs
	copy_with_subs(Body_Item, Vars, Current_Subs, BI_Copy, New_Subs),
	format("body item with vars: ~w~n", [BI_Copy]),
	(	BI_Copy = Fact
	-> 	(
			% body item match, recurse over rest of body
			%append(Current_Matches, [Fact], Next_Matches),
			chase_rule_helper2(Facts, Vars, Next_Vars, Rule, Rest, Facts, New_Subs, Current_Heads, Next_Heads)
		)
	; 	(
			% no match, no updates
			Next_Heads = Current_Heads,
			Next_Vars = Vars
		)
	),
	% recurse over rest of facts, repeating the same body item
	chase_rule_helper2(Facts, Next_Vars, New_Vars, Rule, [Body_Item|Rest], Rest_Facts, Current_Subs, Next_Heads, New_Heads).




% VARS -> BNODES
% separate facts from rules and collect;
% replace vars with bnodes (respecting scope) and collect associations
% apply local scoping to rules during replacement
make_kb(KB, Facts, Rules, Vars) :-
	% give fresh vars to every rule to simulate local scoping
	findall(
		Scoped_Rule,
		(
			member(Rule, KB),
			(	Rule = (_ :- _)
			->	copy_term(Rule, Scoped_Rule)
			;	Scoped_Rule = Rule
			)
		),
		Scoped_KB
	),

	make_kb_helper(Scoped_KB, Facts, Rules, _{}, Vars).

make_kb_helper([], [], [], Vars, Vars) :-
	format("Make kb done.~n",[]).

make_kb_helper([fact(S,P,O) | KB], [New_Fact | New_Facts], New_Rules, Vars, New_Vars) :-
	format("Make fact: ~w~n", [fact(S,P,O)]),
	make_fact(fact(S,P,O), Vars, New_Fact, Next_Vars),
	make_kb_helper(KB, New_Facts, New_Rules, Next_Vars, New_Vars).

make_kb_helper([(Head :- Body) | KB], New_Facts, [New_Rule | New_Rules], Vars, New_Vars) :-
	format("Make rule: ~w~n", [(Head :- Body)]),
	make_rule((Head :- Body), Vars, New_Rule, Next_Vars),
	format("Made rule: ~w~n", [New_Rule]),
	make_kb_helper(KB, New_Facts, New_Rules, Next_Vars, New_Vars).
	
make_rule(Rule, Subs, New_Rule, New_Subs) :-
	Rule = (Head :- Body),
	make_list(Head, Subs, New_Head, Next_Subs),
	make_list(Body, Next_Subs, New_Body, New_Subs),
	New_Rule = (New_Head :- New_Body).

make_list([], Subs, [], Subs).
make_list([fact(S,P,O) | Facts], Subs, [New_Fact | New_Facts], New_Subs) :-
	!,
	make_fact(fact(S,P,O), Subs, New_Fact, Next_Subs),
	make_list(Facts, Next_Subs, New_Facts, New_Subs).
make_list([Constraint | Facts], Subs, [New_Constraint | New_Facts], New_Subs) :-
	Constraint =.. [F | Args],
	make_args(Args, Subs, New_Args, Next_Subs),
	New_Constraint =.. [F | New_Args],
	make_list(Facts, Next_Subs, New_Facts, New_Subs). 

make_fact(Fact, Subs, New_Fact, New_Subs) :-
	Fact =.. [fact | Args],
	make_args(Args, Subs, New_Args, New_Subs),
	New_Fact =.. [fact | New_Args].
make_args([], Subs, [], Subs).
make_args([Arg | Args], Subs, [Arg | New_Args], New_Subs) :-
	nonvar(Arg),
	make_args(Args, Subs, New_Args, New_Subs).
make_args([Arg | Args], Subs, [New_Arg | New_Args], New_Subs) :-
	var(Arg),
	gensym("bn",New_Arg),
	dict_pairs(Subs, _, Subs_Pairs),
	append(Subs_Pairs, [New_Arg-_], Next_Subs_Pairs),
	dict_pairs(Next_Subs, _, Next_Subs_Pairs),
	Arg = New_Arg,
	make_args(Args, Next_Subs, New_Args, New_Subs).





% BNODES -> VARS
copy_list_with_subs([], _, Subs, [], Subs).
copy_list_with_subs([Fact | Facts], Vars, Subs, [New_Fact | New_Facts], New_Subs) :-
	copy_with_subs(Fact, Vars, Subs, New_Fact, Next_Subs),
	copy_list_with_subs(Facts, Vars, Next_Subs, New_Facts, New_Subs).

copy_with_subs(Fact, Vars, Subs, New_Fact, New_Subs) :-
	Fact =.. [F | Args],
	copy_args_with_subs(Args, Vars, Subs, New_Args, New_Subs),
	New_Fact =.. [F | New_Args].

copy_args_with_subs([], _, Subs, [], Subs).
copy_args_with_subs([Arg | Args], Vars, Subs, [New_Arg | New_Args], New_Subs) :-
	copy_arg_with_subs(Arg, Vars, Subs, New_Arg, Next_Subs),
	copy_args_with_subs(Args, Vars, Next_Subs, New_Args, New_Subs).

copy_arg_with_subs(Arg, Vars, Subs, New_Arg, New_Subs) :-
		get_dict(Arg, Vars, _) 
	-> 	(
			get_dict(Arg, Subs, New_Arg)
		->	New_Subs = Subs
		;
			(
			dict_pairs(Subs, _, Pairs),
			append(Pairs, [Arg-New_Arg], New_Pairs),
			dict_pairs(New_Subs, _, New_Pairs)
			%New_Subs = Subs.put(_{Arg:New_Arg})
			)
		)
	;	(
			New_Arg = Arg,
			New_Subs = Subs
		).




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

:-  op(  3,  fx,   [ not ]).
:-  op(  4,  xfx,  [ and ]).
:-  op(  4,  xfx,  [ or ]).
:-  op(  2,  xfx,  [ implies ]).
:-  op(  2,  fx,   [ ? ]).
:-	op(  1,  fx,   [ * ]).

'*'(_) :- true.


% this method repeats solutions
sat1(Solution) :-
	Bool = [true, false],
	Solution = [P, Q, R],
	member(P, Bool),
	member(Q, Bool),
	member(R, Bool),
	(P ; Q),
	(P ; \+Q),
	(\+P ; Q),
	(\+P ; (\+Q ; \+R)),
	(\+P ; R).

sat2(Solution) :-
	Bool = [true, false],
	Solution = [P, Q, R],
	member(P, Bool),
	member(Q, Bool),
	member(R, Bool),
	format("Trying: ~w, ~w, ~w~n", [P,Q,R]),
	(P ; (Q ; R)),
	format("(~w ; (~w ; ~w)) succeeded~n", [P, Q, R]),
	(\+P ; \+R),
	format("(\\+~w ; \\+~w) succeeded", [P, R]).

sat3(Solution) :-
	Bool = [true, false],
	Solution = [P, Q, R],
	member(P, Bool),
	member(Q, Bool),
	member(R, Bool),
	(P ; (Q ; R)),
	!,
	(\+P ; \+R).

% logical or; the distinction between which path we took won't matter until we're using actual
% values / relations as in FOL
or(A, B) :- A -> true ; B.

% and now it doesn't repeat solutions and avoids some work
sat4(Solution) :-
	Bool = [true, false],
	Solution = [P, Q, R],
	member(P, Bool),
	member(Q, Bool),
	member(R, Bool),
	(P or (Q or R)),
	((\+P) or (\+R)). % need parens otherwise "Syntax error: Operator priority clash"

% logical not; because \+ can't handle vars
not(A) :- var(A) or (\+A).

% but _or_ still fails when it's arguments are vars, so we need something like this too
'?'(A) :- var(A) or A.

/*
Partial assignments
*/
sat5(Solution) :-
	Bool = [true, false],
	Solution = [P, Q, R],
	member(P, Bool),
	sat5_formulas(P, Q, R),
	member(Q, Bool),
	sat5_formulas(P, Q, R),
	member(R, Bool),
	sat5_formulas(P, Q, R).

sat5_formulas(P, Q, R) :-
	(?P or (?Q or ?R)),
	(not P or not R).

/*
Ok so we've got partial assignments, but how do we know they're actually working?
Have to be able to look at the search path.
*/
sat6a(Solution) :-
	Bool = [true, false],
	Solution = [P, Q, R],
	member(P, Bool),
	format("Trying: ~w, ~w, ~w~n", [P, Q, R]),
	member(Q, Bool),
	format("Trying: ~w, ~w, ~w~n", [P, Q, R]),
	member(R, Bool),
	format("Trying: ~w, ~w, ~w~n", [P, Q, R]),
	sat6a_formulas(P, Q, R),
	sat6a_formulas(P, Q, R),
	sat6a_formulas(P, Q, R).

sat6a_formulas(P, Q, R) :-
	?P or (?Q or ?R),
	not P or not R,
	not P.


% we can see in the trace that it immediately prunes every case where P = true
sat6b(Solution) :-
	Bool = [true, false],
	Solution = [P, Q, R],
	member(P, Bool),
	format("Trying: ~w, ~w, ~w~n", [P, Q, R]),
	sat6b_formulas(P, Q, R),
	member(Q, Bool),
	format("Trying: ~w, ~w, ~w~n", [P, Q, R]),
	sat6b_formulas(P, Q, R),
	member(R, Bool),
	format("Trying: ~w, ~w, ~w~n", [P, Q, R]),
	sat6b_formulas(P, Q, R).

sat6b_formulas(P, Q, R) :-
	?P or (?Q or ?R),
	not P or not R,
	not P.

% let's abstract some:
sat7([P, Q, R]) :-
	sat7_solve(
		[P, Q, R],
		[
			?P or (?Q or ?R),
			not P or not R,
			not P
		]
	).

sat7_solve(Vars, Formulas) :-
	sat7_solve_helper(Vars, Vars, Formulas).

sat7_solve_helper(_, [], _).
sat7_solve_helper(All_Vars, [Var | Vars], Formulas) :-
	member(Var, [true, false]),
	format("Trying: ~w~n", [All_Vars]),
	sat7_formulas(Formulas),
	sat7_solve_helper(All_Vars, Vars, Formulas).
	

sat7_formulas([]).
sat7_formulas([Formula | Formulas]) :-
	Formula,
	sat7_formulas(Formulas).
	


/*
Standard formula simplification:
* ignoring satisfied formulas
* eliminating contradictory disjuncts

Along with:
* reduced representation
* simplifications based on this reduced representation
* more flexible inference order on vars
* finding multiple solutions at once


The basic idea: every variable is associated with a set of clauses where it appears true, and
a set of clauses where it appears false (these sets may be empty), ex:

	Variables index:
	_{
		p: _{
			true: [0,1],
			false: [2,3,4]
		},
		q: _{
			false:[1,3],
			true:[0,2]
		},
		r: _{
			false:[3],
			true:[4]
		}
	}

	Clauses:
	0:[p:true,q:true]
	1:[p:true,q:false]
	2:[p:false,q:true]
	3:[p:false,q:false,r:false]
	4:[p:false,r:true]

We need to satisfy all the clauses simultaneously. In this representation, this amounts to taking
unions of the clause-sets associated with each variable(-instantiation) and seeing if they produce
the whole set, so we only have to work with basic operations on these simple sets rather than 
potentially more complex operations on more complex/"rich" formula expressions. We can also perform
operations with multiple clauses simultaneously, and this allows for implementing the formula
simplification operations: ignoring satisfied formulas, eliminating contradictory disjuncts, and going
directly to the next viable candidate (variable,clause) pair. Because the goal is to satisfy all the
formulas, we need to direct the search based on what formulas still need to be satisfied. A variable
that would otherwise be in the search-path of a basic in-variable-order inferencer might not actually
be a relevant variable in the remaining clauses, so we should go as directly as possible to the next viable
(variable,clause) pair, and if all the clauses are satisfied we should report a solution; if other
variables are yet to be instantiated, then we can instantiate them arbitrarily. However, now that we're
determining the variable-order from the clause-set, we need to aim to preserve: 
	a) completeness;
	b) non-duplication
	

Unsatisfiable example run (using the Vars and Equations above):

	___ = ?       + ?     + ?		= {}			% find 0
	t__ = {0,1}   + ?     + ?		= {0,1}			% find 2
	tt_ = {0,1}   + {0,2} + ?		= {0,1,2}		% find 3
	ttt = {0,1}   + {0,2} + {3}		= {0,1,2,3}		% fail
	tt_ = {0,1}   + {0,2} + ?		= {0,1,2}		% can't find 3 any other way from here
	t__ = {0,1}   + ?     + ?		= {0,1}			% can't find 2 any other way from here
	f__ = {2,3,4} + ?     + ?		= {2,3,4}		% set P to false because we've exhausted the true case; find 0
	ft_ = {2,3,4} + {0,2} + ?		= {0,2,3,4}		% can't find 1 any way from here
	f__ = {2,3,4} + ?     + ?       = {2,3,4}		% can't find 0 any other way from here
	___ = {}	  + ?	  + ?		= {}			% no other possibilities for P; done: unsat


Satisfiable example run:
	Variables index:
	_{
		p: _{
			true: [0],
			false: [1]
		},
		q: _{
			false:[],
			true:[0]
		},
		r: _{
			false:[1],
			true:[0]
		}
	}

	Clauses:
	0:[p:true,q:true,r:true],
	1:[p:false,r:false]

	___ = ?       + ?     + ?       = {}			% find 0
	t__ = {0}     + ?     + ?       = {0}			% find 1
	t_f = {0}     + ?	  + {1}     = {0,1}         % sat: t_f: ttf; tft
	t_t = {0}     + ?     + {0}		= {0}			% failed to find result with remaining variables
	f__ = {1}     + ?     + ?       = {1}			% find 0
	ft_ = {1}     + {0}   + ?       = {0,1}         % sat: ft_: ftt; ftf; increment arg-2
	ff_ = {1}     + {}    + ?		= {1}			% find 0: found
	fft = {1}     + {}    + {0}		= {0,1}			% sat: fft
	ff_	= {1}     + {}    + ?       = {1}			% find 0: not found
	f__ = {1}     + ?     + ?       = {1}			% arg-2 increment done
	___ = ?       + ?     + ?       = {}			% arg-1 increment done

	

*/


sat8a(Solution) :-
	Solution = [P, Q, R],
	Vars = _{
		p: _{
			var: P,
			true: [0,1],
			false: [2,3,4]
		},
		q: _{
			var: Q,
			false:[1,3],
			true:[0,2]
		},
		r: _{
			var: R,
			false:[3],
			true:[4]
		}
	},


	Formulas = [
		[p:true,q:true],
		[p:true,q:false],
		[p:false,q:true],
		[p:false,q:false,r:false],
		[p:false,r:true]
	],
	
	sat8_solve(Vars, Formulas, [0,1,2,3,4], []),
	sat8_fill_vars(Solution).





sat8b(Solution) :-
	Solution = [P, Q, R],
	Vars = _{
		p: _{
			var: P,
			true: [0],
			false: [1]
		},
	q: _{
			var: Q,
			true:[0],
			false:[]
		},
		r: _{
			var: R,
			false:[1],
			true:[0]
		}
	},


	Formulas = [
		[p:true,q:true,r:true],
		[p:false,r:false]
	],
	
	sat8_solve(Vars, Formulas, [0,1], []),
	% it determines a solution when all equations are solved, not when all
	% vars are satisfied; the remaining vars can be filled in arbitrarily
	sat8_fill_vars(Solution).



sat8_solve(_, _, [], _).
sat8_solve(Vars, Formulas, [N | Rest], Used_Vars) :-
	nth0(N, Formulas, Formula),
	member(Var:Val, Formula), % so at this point it's going to commit to a DFS starting from this var but directed by the formulas
	\+member(Var, Used_Vars), % needs to not go back to try any other vars after this
	!,
	(
		Vars.Var.var = Val
	;
		not(Val,NVal),
		Vars.Var.var = NVal
	),
	append(Used_Vars, [Var], New_Used_Vars),
	subtract([N | Rest], Vars.Var.(Vars.Var.var), New_Rest),
	sat8_solve(Vars, Formulas, New_Rest, New_Used_Vars).

sat8_fill_vars([]).
sat8_fill_vars([X | Rest]) :-
	member(X,[true,false]),
	sat8_fill_vars(Rest).

not(true,false).
not(false,true).



/*
Unit propagation:
* if all but one variable in a clause are instantiated as false, then we can instantiate that variable as true
* is sat8 already encompassing the functionality of unit propagation? how can we tell?
* still leaves open the possibility of trying an instantiation that a later unit would rule out
* unit-clause detection
	* loop through clauses and check for units
	* is there a better way?
* prune all false cases
*/

/*
Pure literal elimination:
* is sat8 already encompassing the functionality of pure literal elimination? how can we tell?
*/

/*
Eliminate any clauses where a variable appears both positive and negative
Eliminate any repeated literals in a clause

*/

/*
Conflict-driven clause-learning
* DP/DPLL backbone
* "guess level"
* conflicts
* clause-learning
* non-chronological back-jump
* implication graph <-> unit propagation
* find cut leading to conflict
* generate conflicting condition from cut
* make negation of conflicting condition into a new clause
*/

/*
Linear time 2-SAT solver: based on transformation into implication graph
* an instance is satisfiable iff. no literal and its negation belong to the same "strongly-connected component"
* "strongly connected component"
* 2-SAT vars/clauses ratio phase-transition of probability of satisfiability
*/

/*
Resolution
*/

/*
Domain constraints
* try each variable independently, eliminate any values that don't satisfy; if any domain becomes empty then unsat
* then try w/ two variables; eliminate any combinations that don't satisfy...
*/

/*
Binary decision diagrams
* want result formula as small as possible
* want canonical normal form for expressions
	* for the same function and same variable order, there should be only one graph representing this function
* identify and remove redundant nodes & edges
* reduction rule 1: merge equivalent leaves
* reduction rule 2: merge isomorphic children
	* isomorphic = same variable and identical children
* reduction rule 3: eliminate redundant tests
* "reduced-ordered BDD": two functions identical iff ROBDD graphs isomorphic
* recursive methods:
	* URP:
		* shannon cofactor divide & conquery
* operators: AND, OR, NOT, EXOR, CoFactor, Univrsals, Existentials, Satisfy..
	* implemented such that if inputs are shared, reduced, ordered BDDs, then the outputs are too.
* graph-sharing
* boolean function equality by pointer-comparison in shared BDDs representation
* checking for inputs that cause different outputs of two functions f & g by checking satisfiability of BDD for f xor g
* checking for tautologies: tautology exactly when the BDD is pointer-equal to BDD for primitive tautology f(x) = 1
* SAT over BDDs: all paths from root to the 1 leaf are solutions
* BDDs and Bayesian inferencing
* influence of variable-ordering on BDD complexity
* works well on:
	* carry chain circuits
		* best-case BDD: linear
		* worst-case BDD: exponential
		* heuristic: alternating variable order a_1 b_1 a_2 b_2 ...
		* adders
		* subtractors
		* comparators
		* priority encoders
* doesn't work well on:
	* multiplication
		* best-case BDD: exponential
		* there are other representations with canonical forms for representating multiplication circuits more efficiently

*/

/*
CLP(B)
*/


/*
Pre-emptive formula simplification?
*/

/*
Extending to FOL
* replacing boolean literals with relational propositions ex. p(x) and r(x,y) instead of just boolean p,q,...
* unification
* reduction to equisatisfiable propositional CNF; solve by SAT
	* problem: how to extract the model from this method?


*/

/*
SMT: Satisfiability Modulo Theories

*/

/*
Parsing
standard formats
debugging
proper test suite
*/

% stuff

:- use_module(library(clpq)).

test_run :-
	Formulas = [
		assets = equity + liabilities,
		equity = capital + retained_earnings,
		retained_earnings = net_income - dividends,
		net_income = income - expenses,
		income / avg_sales_price = sales_count
	],

	Values = [
		expenses = 5,
		dividends = 3,
		liabilities = 4,
		capital = 11,
		avg_sales_price = 2,
		sales_count = 5
	],

	append([Formulas, Values], Context),

	solve_for(
		[
			assets,
			equity,
			retained_earnings,
			net_income
		], 
		Context, 
		Results
	),

	writeln(Results),
	format("Assets: ~w~n", [Results.assets]).

	
% produce a dict of vars
	
analyze_term(X + Y, Vars_In, Vars_Out) :-
	!,
	analyze_term(X,Vars_In, Vars_Out1),
	analyze_term(Y,Vars_Out1, Vars_Out).

analyze_term(X - Y, Vars_In, Vars_Out) :-
	!,
	analyze_term(X,Vars_In, Vars_Out1),
	analyze_term(Y,Vars_Out1, Vars_Out).

analyze_term(X * Y, Vars_In, Vars_Out) :-
	!,
	analyze_term(X, Vars_In, Vars_Out1),
	analyze_term(Y, Vars_Out1, Vars_Out).

analyze_term(X / Y, Vars_In, Vars_Out) :-
	!,
	analyze_term(X, Vars_In, Vars_Out1),
	analyze_term(Y, Vars_Out1, Vars_Out).

analyze_term(Atomic, Vars_In, Vars_Out) :-
	atom(Atomic),
	!,
	Vars_Out = Vars_In.put(Atomic,_).

analyze_term(Number, Vars_In, Vars_In) :-
	number(Number),
	!.

analyze_rel(LHS = RHS, Vars_In, Vars_Out) :-
	analyze_term(LHS, Vars_In, Vars_Out1),
	analyze_term(RHS, Vars_Out1, Vars_Out).

analyze_context([], Vars_In, Vars_In).

analyze_context([Rel | Rest], Vars_In, Vars_Out) :-
	analyze_rel(Rel, Vars_In, Vars_Out1),
	analyze_context(Rest, Vars_Out1, Vars_Out).

	
	
	
	
	
	
clpqify_term(X + Y, Vars, X2 + Y2) :-
	!,
	clpqify_term(X, Vars, X2),
	clpqify_term(Y, Vars, Y2).

clpqify_term(X - Y, Vars, X2 - Y2) :-
	!,
	clpqify_term(X, Vars, X2),
	clpqify_term(Y, Vars, Y2).

clpqify_term(X * Y, Vars, X2 * Y2) :-
	!,
	clpqify_term(X, Vars, X2),
	clpqify_term(Y, Vars, Y2).

clpqify_term(X / Y, Vars, X2 / Y2) :-
	!,
	clpqify_term(X, Vars, X2),
	clpqify_term(Y, Vars, Y2).

clpqify_term(Atomic, Vars, Var) :-
	atom(Atomic),
	!,
	Var = Vars.Atomic.

clpqify_term(Number, _, Number) :-
	number(Number),
	!.

clpqify_rel(LHS = RHS, Vars) :-
	clpqify_term(LHS, Vars, LHS2),
	clpqify_term(RHS, Vars, RHS2),
	{LHS2 =:= RHS2},
	!.

clpqify_context([], Vars) :- print_stuff(Vars).

clpqify_context([Rel | Rest], Vars) :-
	print_stuff(Vars),
	clpqify_rel(Rel, Vars),
	clpqify_context(Rest, Vars).

print_stuff(X) :-
	print_term(X, [attributes(write)]), nl,writeln('that is,').
	%dict_pairs(X, _, Pairs),
	%maplist(print_with_attrs, Pairs), nl,nl.
	
print_with_attrs(X) :-
	print_term(X, [attributes(write)]), nl.
	       
	
	
	
	
	
	
solve(Context, Vars) :-
	analyze_context(Context, _{}, Vars),
	clpqify_context(Context, Vars).


solve_for(Values, Context, Results) :-
	solve(Context, Vars),
	findall(
		Key-Value,
		(
			member(Key,Values),
			Value = Vars.Key
		),
		Pairs
	),
	dict_pairs(Results, results, Pairs).

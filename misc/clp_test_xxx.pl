:- use_module(library(clpfd)).
:- use_module(library(clpq)).
:- use_module('./clp_nonlinear').



x(Running_Balance, [Installment_Amount|Installment_Amounts], [ISR|PTs]) :- 
	%PT = payment type, 0 for regular, 1 for baloon
	ISR in 0..1,
	ISB #= 1-ISR,

	{Installment_Amount = HP_Repayment_Amount * ISR + Balloon_Amount * ISB},
	{Balloon_Amount > HP_Repayment_Amount},
	{HP_Repayment_Amount = 100},
	{Running_Balance - Installment_Amount = New_Running_Balance},

	x(New_Running_Balance, Installment_Amounts, PTs).
x(0, [], []).

x2(Running_Balance, [Installment_Amount|Installment_Amounts], [ISR|PTs]) :- 
	%PT = payment type, 0 for regular, 1 for baloon
	ISR in 0..1,
	ISB #= 1-ISR,

	solve(ISR, [
		(Installment_Amount = HP_Repayment_Amount * ISR + Balloon_Amount * ISB),
		(Balloon_Amount > HP_Repayment_Amount),
		(HP_Repayment_Amount = 100),
		(Running_Balance - Installment_Amount = New_Running_Balance)
	]),

	x2(New_Running_Balance, Installment_Amounts, PTs).
	
x2(0, [], []).


%x(3000, [100,100,100,700,100,100,100,700,100,100,700,100], PTs),label(PTs).


:- findall(PTss, (x(3000, [100,100,100,700,100,100,100,700,100,100,700,100], PTs),label(PTs)), PTs), writeq(PTss).

gen_test(0, _, _, []).
gen_test(N, A, B, [I | R]) :-
	N > 0, !,
	(
		0 =:= mod(N,3)
	->
		I = B
	;
		I = A
	),
	M is N-1,
	gen_test(M, A, B, R).

y([_|Whatevers],[ISR|PTs]) :- 
	ISR in 0..1,
	y(Whatevers, PTs).
	
y([], []).



test_installments([
	i(1, 100),
	i(1, 100),
	i(1, 100),
	i(0, 700),

	i(1, 100),
	i(1, 100),
	i(1, 100),
	i(0, 700),

	i(1, 100),
	i(1, 100),
	i(1, 100),
	i(0, _),

	i(1, 100),
	i(1, 100),
	i(1, 100),
	i(0, 700)]).


xx(Running_Balance, [I|Installments]) :- 
	I = i(ISR,Installment_Amount),
	ISR in 0..1,
	ISB #= 1-ISR,
	freeze(ISR, (writeq(I),nl)),
	{Installment_Amount = HP_Repayment_Amount * ISR + Balloon_Amount * ISB},
	{Balloon_Amount > HP_Repayment_Amount},
	{HP_Repayment_Amount = 100},
	{Running_Balance - Installment_Amount = New_Running_Balance},
	xx(New_Running_Balance, Installments).
xx(0, []).















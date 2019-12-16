:- use_module(library(clpfd)).
:- use_module(library(clpq)).




x(Running_Balance, [Installment_Amount|Installment_Amounts], [ISR|PTs]) :- 
	%PT = payment type, 0 for regular, 1 for baloon
	ISR in 0..1,
	ISB #= 1-ISR,/*
	{Installment_Amount = HP_Repayment_Amount * ISR + Balloon_Amount * ISB},
	{Balloon_Amount > HP_Repayment_Amount},
	{HP_Repayment_Amount = 7},
	{Running_Balance - Installment_Amount = New_Running_Balance},*/
	x(New_Running_Balance, Installment_Amounts, PTs).
	
x(0, [], []).


:- findall(PTss, (x(3000, [100,100,100,700,100,100,100,700,100,100,700,100], PTs),label(PTs)), PTs), writeq(PTss).




y([_|Whatevers],[ISR|PTs]) :- 
	ISR in 0..1,
	y(Whatevers, PTs).
	
y([], []).


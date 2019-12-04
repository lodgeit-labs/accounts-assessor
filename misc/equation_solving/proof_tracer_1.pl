
:- set_prolog_flag(answer_write_options, [ max_depth(100)]).

explain(Formula) :-
   solve(Formula, Proof),
   write(Proof).

% Tiny meta-interpreter
solve(true, true) :- !.

solve((A, B), (ProofA, ProofB)):-
   solve(A, ProofA),
   solve(B, ProofB),
   !.

solve(Formula, Formula) :-
   predicate_property(Formula, built_in),
   call(Formula),
   !.
/*
solve(A, (A :- Why)):-
   call(A, because(Why)),
   !.
*/

solve(A, (A :- ProofB)):-
   catch(
      clause(A, B),
      E,
      false
   ),
   solve(B, ProofB),
   !.

solve(A, (A :- Why)):-
   add_argument(A, because(Why), A2),
   clause(A2, B),
   solve(B, _ProofB),
   !.


   
add_argument(Term, Add, Term2) :-
	functor(Term, Name, Arity),
	Arity2 is Arity + 1,
	functor(Term2, Name, Arity2),
	copy_all_args(Term, Term2, Arity),
	arg(Arity2, Term2, Add).

copy_all_args(_, _, 0) :- !.
	
copy_all_args(Term, Term2, Arg) :-
	arg(Arg, Term, Value),
	arg(Arg, Term2, Value),
	Arg2 is Arg - 1,
	copy_all_args(Term, Term2, Arg2).
	
   
% Formula
net_assets(ID, Value3, ['Assets', '$', Value1, less, liabilities, '$', Value2, equals, '$', Value3]) :-
   assets(ID, Value1),
   liabilities(ID, Value2),
   Value3 is Value1 - Value2.

% Facts
assets('001', 20).
liabilities('001', 10).

% -------------------------------------------------------------------------------------

% Net Assets = $10. How? Assets $20 less liabilities $10 equals $10
%
test0 :-
	explain(net_assets('001', 10, _)).
%
% net_assets(001,10,[Assets,$,20,less,liabilities,$,10,equals,$,10]):-(assets(001,20):-true),(liabilities(001,10):-true),10 is 20-10
%
% Why = [Assets,$,20,less,liabilities,$,10,equals,$,10] 
% -------------------------------------------------------------------------------------


:- use_module('../lib/utils', [user:goal_expansion/2, pretty_term_string/2]).



/* ( from https://github.com/aindilis/aop-swipl ) */

factorial2(0, R, R, because('factorial 0 is 0.')).
factorial2(N_In, Acc_In, R, because(Why :- Why2)) :-
	N_In \= 0,
	compile_with_variable_names_preserved((
		NewN = N - 1,
		NewAcc = Acc * N),
		Namings),
	term_string(NewN, Formula_String1a, [Namings]),
	term_string(NewAcc, Formula_String2a, [Namings]),
	N = N_In,
	Acc = Acc_In,
	term_string(NewN, Formula_String1b, [Namings]),
	term_string(NewAcc, Formula_String2b, [Namings]),
	NewN_Out is NewN,
	NewAcc_Out is NewAcc,
	atomic_list_concat(['NewN=',Formula_String1a,'(', Formula_String1b,'), NewAcc=', Formula_String2a, '(',Formula_String2b,')'], Why),
	factorial2(NewN_Out, NewAcc_Out, R, Why2).

%:- explain(factorial2(5,1,_R)).




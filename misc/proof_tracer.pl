/*
What I'm hoping we can aim for is ability to leverage the logic in controlled natural language interactions on both input & output. So we can easily build/expose queries from some chat services like Alexa or Dialogflow. And so the system can ultimately express controlled natural language output as the levels of logical complexity increase i.e. the system can generate an easy to follow description of how a result from a query was derived i.e. Net Assets = $10. How? Assets $20 less liabilities $10 equals $10.

What will be great is if we can have a toolkit that helps to guide accountant programmers in writing queries in as close to natural language as possible. Possibly we can interface some components that allow an accountant to write queries super easily with a guide tool i.e .set of guard rails that help to ensure the logic of the expression but with maximal freedom whenever/ wherever it makes sense i.e. asAt or at or point in time for querying instant. fromTo, profitLoss, through time to express duration. And any manner of date construct 30 June 2018, 30/06/2018 .. etc.
---
I don't think that you need to translate these formulas in the other direction as long as these formulas are not modified by the logic program. Also if you really want to keep it simple and not show the proof, then you don't need a meta-interpreter at all, and you can construct the explanation via an additional argument in the rule (as shown in the example); it's a bit like building up a syntax tree during parsing but in our case it's an explanation. Alternatively, one can construct a proof (using the meta-interpreter) and then extract the explanation from the proof.

Just a thought: one could do something along the following line (see the code) using a meta-interpreter that answers your questions; note it executes the query and constructs a proof for the answer. But first one has to extract these formulas from XBRL and bring them into a suitable Prolog format.
---
We can also leverage unevaluated prolog arithmetic terms for generating explanations, see livestock standalone endpoint. Unfortunately, at least with swi-prolog, this standard-library mechanism is poorly extensible, and CLP libraries don't seem to make this any better.

A main part of a prolog program "should" read like a declaration of how a result is arrived at. No matter which methods we eventually end up with, we can strive for a declarative style. The main benchmark of that is probably the quality of generated explanations. 

A minor question to resolve is how xbrl formulas tie into this project. Can we reasonably describe all accounting logic in them?

With regards to natural language question answering, i'm of the opinion that practical value lies mainly in controlled natural languages (CNLs). Truly natural language interaction can possibly eventually leverage the controlled language layer. The first layer the user sees is the user interface that can have varying degrees of support for CNL interaction. At one extreme is a drag-and-drop sentence builder, on another extreme is perhaps voice input.
It should be noted that naturalness in CNLs should not be a goal in itself, it is simply one method to make interaction with computer easier. Oftentimes, more dense sub-languages, specialized GUIs, and other tools are more helpful. However, CNLs are the next cool thing, and a low hanging fruit, for which all prerequisite technologies and theories have already been developed (PENG, GF..).
If the UI is the first layer and the grammar/parser the second, then the fourth layer is perhaps the model of the world and the reasoning engine and rules to do useful things with it, and the third layer is the glue between ASTs and the model.
On this level we can compare PENG, Attempto, Inform 7 for example. 

From architectural perspective on this project, the goal is probably mostly server-sided logic, but we can try to write portable and declarative code, which could at some point ease migration onto the frontend. 
One consideration is the "laziness" and declarativeness of the query engine. At one extreme, it can try to generate all explanations while it does it's computations.... (to be continued).

*/

/*
Note that our model (domain of discourse) on this project should primarily be xbrl facts or other related concepts. Thus we are not asking "why is the ledger request output such and such text", but "why is assets $20".
A functional language perhaps yields itself better to explaining it's results. Assets value might be a function of balance sheet. Balance sheet a function of ledger, ledger a function of bank statements (to simplify).
Assets is $20 because that's the sum of vectors of all transactions with 'Assets' as their account or their account's ancestor account. We can look into ciao and mercury for support for lazy evaluation (and functional syntax).

Lets say what we hardcode is the traversal of the account hierarchy for the purpose of producing xbrl facts.
The value of each fact is extracted by predicate account_balance_at_date(Account, Balance, Explanation).
Explanations have been simply stored alongside balances while the balance sheet structure was generated.

In current codebase we have:

balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Day, Balance_Transformed) :-
	transactions_before_day_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Day, Filtered_Transactions),
	transaction_vectors_total(Filtered_Transactions, Balance),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Balance, Balance_Transformed).

A proof trace would obviously be horrendous. What we care about is something like:
Balance_Transformed = (fact(Balance_Transformed_Value), explanation(

(fact(coord(50,0)), explanation(
	transactions_before_day_on_account_and_subaccounts(
		Accounts,
		^ an uri to accounts hierarchy definition in outputted xbrl
				
		Transactions, 
		^ again this would have been already output in xbrl gl format, with some identifier that we can reference.

		'Assets', 
		^ here we would have an uri that identifies that assets account definition in our xbrl instance.
				
		Day, 
		
		Filtered_Transactions),


	transaction_vectors_total(Filtered_Transactions, Balance),


*/


/* a small meta-interpreter that builds a proof-tree as it goes, Rolf's original version: 

% -------------------------------------------------------------------------------------

% Net Assets = $10. How? Assets $20 less liabilities $10 equals $10
%
% ?- explain(net_assets('001', 10, Why)).
%
% net_assets(001,10,[Assets,$,20,less,liabilities,$,10,equals,$,10]):-(assets(001,20):-true),(liabilities(001,10):-true),10 is 20-10
%
% Why = [Assets,$,20,less,liabilities,$,10,equals,$,10] 
% -------------------------------------------------------------------------------------

:- set_prolog_flag(answer_write_options, [ max_depth(100)]).

explain(Formula) :-
   solve(Formula, Proof),
   write(Proof).

% Tiny meta-interpreter
solve(true, true) :- !.

solve((A, B), (ProofA, ProofB)):-
   solve(A, ProofA),
   solve(B, ProofB).

solve(Formula, Formula) :-
   predicate_property(Formula, built_in),
   call(Formula).

solve(A, (A :- ProofB)):-
   clause(A, B),
   solve(B, ProofB).

% Formula
net_assets(ID, Value3, ['Assets', '$', Value1, less, liabilities, '$', Value2, equals, '$', Value3]) :-
   assets(ID, Value1),
   liabilities(ID, Value2),
   Value3 is Value1 - Value2.

% Facts
assets('001', 20).
liabilities('001', 10).

*/

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




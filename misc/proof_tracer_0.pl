% a small meta-interpreter that builds a proof-tree as it goes, Rolf's original version: 

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

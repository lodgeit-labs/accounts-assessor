/* -*- Mode:Prolog; coding:iso-8859-1; indent-tabs-mode:true; prolog-indent-width:8; prolog-paren-indent:8; tab-width:8; -*- */



:- dynamic result/1.

do(Pred) :-
	call(Pred, Result),
	assertz(result(Result)).

yield_results(R) :-
	result(R).

find_all_results(Results) :-
	findall(R, yield_results(R), Results).


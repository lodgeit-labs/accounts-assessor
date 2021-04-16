% -------------------------------------------------------------------
% Exchanges the given coordinate, Amount, into the first unit from Bases for which an
% exchange on the day Day is possible. If the source unit is not found in Bases, then Amount is left as is.
% in practice, we never pass multiple items in Bases, so this mechanism could be simplified away.

% - no bases to use, leave as it is
exchange_amount(_, _, [], Amount, Amount) :- !.

exchange_amount(Exchange_Rates, Day, [Bases_Hd | _], coord(Unit, Debit), Amount_Exchanged) :-
	exchange_rate(Exchange_Rates, Day, Unit, Bases_Hd, Exchange_Rate),
	Debit_Exchanged is Debit * Exchange_Rate,
	Amount_Exchanged = coord(Bases_Hd, Debit_Exchanged),
	!.

exchange_amount(Exchange_Rates, Day, [_ | Bases_Tl], Coord, Amount_Exchanged) :-
	exchange_amount(Exchange_Rates, Day, Bases_Tl, Coord, Amount_Exchanged).


% Using the exchange rates from the day Day, change the given vector into
% units in Bases.

% Where two different coordinates have been mapped to the same basis,
% combine them. If a coordinate cannot be exchanged into a unit from Bases, then it is
% put into the result as is.

/*vec_change_bases(_, _, _, [], []) :- !.*/


/*vec_change_bases(Exchange_Rates, Day, Bases, As, Bs) :-
	vec_change_bases(nothrow, Exchange_Rates, Day, Bases, As, Bs).
*/
 vec_change_bases(Exchange_Rates, Day, Bases, As, Bs) :-
 	push_format('convert ~q to ~q at ~q', [$>round_term(As), Bases, Day]),
	assertion(flatten(Bases, Bases)),
	maplist(exchange_amount(Exchange_Rates, Day, Bases), As, As_Exchanged),
	/*and reduce*/
	vec_add([], As_Exchanged, Bs),
	pop_context.

 exchange_amount_throw(Exchange_Rates, Day, [Base], coord(Unit, Debit), Amount_Exchanged) :-
	exchange_rate_throw(Exchange_Rates, Day, Unit, Base, Exchange_Rate),
	Debit_Exchanged is Debit * Exchange_Rate,
	Amount_Exchanged = coord(Base, Debit_Exchanged).

 vec_change_bases_throw(Exchange_Rates, Day, Bases, As, Bs) :-
 	push_format('convert ~q to ~q at ~q', [$>round_term(As), Bases, Day]),
	assertion(flatten(Bases, Bases)),
	maplist(exchange_amount_throw(Exchange_Rates, Day, Bases), As, As_Exchanged),
	vec_add([], As_Exchanged, Bs),
	pop_context.


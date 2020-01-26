string_to_json_dict(String, Json_Dict) :-
	setup_call_cleanup(
		new_memory_file(X),
		(
			open_memory_file(X, write, W),
			write(W, String),
			close(W),
			open_memory_file(X, read, R),
			json_read_dict(R, Json_Dict),
			close(R)),
		free_memory_file(X)).

json:json_write_hook(Term, Stream, _, _) :-
	term_dict(Term, Dict),
	json_write(Stream, Dict, [serialize_unknown(true)]).

dict_json_text(Dict, Text) :-
	setup_call_cleanup(
		new_memory_file(X),
		(
			open_memory_file(X, write, S),
			json_write(S, Dict, [serialize_unknown(true)/*,todo tag(type)*/]),
			close(S),
			memory_file_to_string(X, Text)
		),
		free_memory_file(X)).

term_dict(
	Value,
	value{unit:U, amount:A}
) :-
	Value=value(_,_),
	round_term(Value,value(U, A)).

term_dict(
	Coord,
	coord{unit:U2, debit:D2, credit:C2}
) :-
	dr_cr_coord(U0, D0, C0, Coord),
	round_term(U0,U2),
	round_term(D0,D2),
	round_term(C0,C2).

term_dict(
	entry(Account, Balance, Child_sheet_entries, Transactions_count),
	entry{account:Account2, balance:Balance2, child_sheet_entries:Child_sheet_entries2, transactions_count:Transactions_count2}
) :-
	round_term(Account,Account2),
	round_term(Balance,Balance2),
	round_term(Child_sheet_entries,Child_sheet_entries2),
	round_term(Transactions_count,Transactions_count2).

term_dict(
	exchange_rate(Day, Src, Dst, Rate),
	exchange_rate{date:Day, src:Src2, dst:Dst2, rate:Rate2}
) :-
	round_term(Src,Src2),
	round_term(Dst,Dst2),
	round_term(Rate,Rate2).

term_dict(
	date(Y,M,D),
	Str
	%date{day:D, month:M, year:Y}
) :- format_date(date(Y,M,D), Str).

/*
with_cost_per_unit(...,rounded_cost)(rdiv cost))
*/

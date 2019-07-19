
:- ['../../lib/pacioli'].
:- ['../../lib/files'].
:- ['../../lib/pricing'].
:- ['../../lib/utils'].
%:- ['../../lib/depreciation'].

% :- use_module(library(debug), [assertion]).
/*
:- begin_tests(depreciation).
%we can test like this:
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(20,7, 1), _, Final_value), 
	assertion(Final_value == 80.0).
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(20,7, 1), _, Final_value), 
	assertion(Final_value == 80.0).
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(21,7, 1), _, Final_value), 
	assertion(Final_value == 60.0).
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(22,7, 1), _, Final_value), 
	assertion(Final_value == 40.0).
% or just:
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(23,7, 1), _, 20.0).
%but in the case of this module, being a work in progress, it might be best to just test that the predicates
%succeed and dont hardcode a result value yet.
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(20,7, 1), diminishing_value, Final_value).
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(21,7, 1), diminishing_value,Final_value).
test(0) :-
	depreciation_between_two_dates(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(19,7, 1), date(21,7,1),_,Final_value).
test(0) :-
	depreciation_between_two_dates(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(19,12, 31), date(20,7,1),_,Final_value).
test(0) :-
	depreciation_between_two_dates(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(19,7, 1), date(21,7,1),diminishing_value,Final_value).
test(0) :-
	depreciation_between_two_dates(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(19,12, 31), date(20,7,1),diminishing_value,Final_value).

:- end_tests(depreciation).

*/

:- begin_tests(pacioli).


test(0) :-
	vec_units(
		[
			coord(aud, _,_), 
			coord(aud, _,_), 
			coord(usd, _,_)
		], 
		Units0
	), 
	Units0 = [aud, usd],

	vec_units([], []),
	vec_units([coord(aud, 5,7), coord(aud, _,_), coord(Usd, _,_)], [aud, Usd]),
	pacioli:coord_merge(coord(Unit, 1, 2), coord(Unit, 3, 4), coord(Unit, 4, 6)),
	utils:semigroup_foldl(pacioli:coord_merge, [], []),
	utils:semigroup_foldl(pacioli:coord_merge, [value(X, 5)], [value(X, 5)]),
	utils:semigroup_foldl(pacioli:coord_merge, [coord(x, 4, 5), coord(x, 4, 5), coord(x, 4, 5)], [coord(x, 12, 15)]),
	\+utils:semigroup_foldl(pacioli:coord_merge, [coord(y, 4, 5), coord(x, 4, 5), coord(x, 4, 5)], _),
	vec_add([coord(a, 5, 1)], [coord(a, 0.0, 4)], []),
	vec_add([coord(a, 5, 1), coord(b, 0, 0.0)], [coord(b, 7, 7), coord(a, 0.0, 4)], []),
	vec_add([coord(a, 5, 1), coord(b, 1, 0.0)], [coord(a, 0.0, 4)], Res0),
	Res0 = [coord(b, 1.0, 0.0)],
	vec_add([coord(a, 5, 1), coord(b, 1, 0.0), coord(a, 8.0, 4)], [], Res1),
	Res1 = [coord(a, 8.0, 0), coord(b, 1.0, 0.0)],
	vec_add([value('AUD',25)], [value('AUD',50)], [value('AUD',75)]).

:- end_tests(pacioli).


:- begin_tests(files).

test0 :-
    absolute_file_name(my_static('account_hierarchy.xml'), _,
                       [ access(read) ]),
    absolute_file_name(my_static('default_action_taxonomy.xml'), _,
                       [ access(read) ]),
    absolute_file_name(my_tests('endpoint_tests/ledger/ledger-request.xml'), _,
                       [ access(read) ]),
	catch(
		(
			absolute_file_name(my_tests('non_existent_file.which_really_should_not_exist'), _, [ access(read) ]),
			false
		),
        _,
        true).

:- end_tests(files).





:- begin_tests(pricing).

test(0) :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	find_items_to_sell(Pricing_Method, 'TLS', 2, Outstanding_Out, _Outstanding_Out2, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 2, value('AUD',10), date(2000, 1, 1))].
	
test(1) :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	\+find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding_Out, _Outstanding_Out2, _Cost_Of_Goods).

test(2) :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 50), date(2000, 1, 2)), 
		Outstanding_Out, Outstanding_Out2),
	find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding_Out2, _Outstanding_Out3, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 5, value('AUD',25), date(2000, 1, 1)), outstanding('CZK', 'TLS', 1, value('AUD',50), date(2000, 1, 2))].
	
test(3) :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding),
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('USD', 5), date(2000, 1, 2)), 
		Outstanding, Outstanding2),
	find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding2, _Outstanding3, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 5, value('AUD',25), date(2000, 1, 1)), outstanding('CZK', 'TLS', 1, value('USD',5), date(2000, 1, 2))].

:- end_tests(pricing).





:- begin_tests(utils).

test(0) :-
	semigroup_foldl(atom_concat, [], []),
	semigroup_foldl(atom_concat, [aaa], [aaa]),
	semigroup_foldl(atom_concat, [aaa, bbb], [aaabbb]),
	semigroup_foldl(atom_concat, [aaa, bbb, ccc], [aaabbbccc]).

:- end_tests(utils).





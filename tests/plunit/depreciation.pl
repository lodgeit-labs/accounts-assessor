:- ['../../src/depreciation'].
:- use_module(library(debug), [assertion]).

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
:- run_tests.

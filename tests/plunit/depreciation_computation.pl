:- ['../../lib/depreciation_computation'].


:- begin_tests(depreciation).

test(written_down_1, all(Final_value = [80.0])) :-
	% Depreciation rates for motor vehicles depending on the year: 1, 2... after investing. _ signifies all years.
	Rates = [
		depreciation_rate(motor_vehicles, _, 0.2)
		%,depreciation_rate(motor_vehicles, 0, 0.27)
	],
	written_down_value(
			transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), 
			date(20,7, 1),
			_,
			Rates,
			Final_value).

test(written_down_2, all(Final_value = [80.0])) :-
	Rates = [
		depreciation_rate(motor_vehicles, 1, 0.2)
		,depreciation_rate(motor_vehicles, 2, 0.17)
		,depreciation_rate(motor_vehicles, 3, 0.15)
		,depreciation_rate(motor_vehicles, 4, 0.13)
	],
	written_down_value(
			transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), 
			date(20,7, 1),
			_,
			Rates,
			Final_value).

			
/*
test(written_down_3) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, Rates, t_term(100, 0)), date(21,7, 1), _, Final_value), 
	assertion(Final_value == 60.0).

test(written_down_4) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, Rates, t_term(100, 0)), date(22,7, 1), _, Final_value), 
	assertion(Final_value == 40.0).

% or just:
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, Rates, t_term(100, 0)), date(23,7, 1), _, 20.0).

%but in the case of this module, being a work in progress, it might be best to just test that the predicates
%succeed and dont hardcode a result value yet.
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(20,7, 1), diminishing_value, _Final_value).
test(0) :-
	written_down_value(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(21,7, 1), diminishing_value, _Final_value).
test(0) :-
	depreciation_between_two_dates(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(19,7, 1), date(21,7,1),_,_Final_value).
test(0) :-
	depreciation_between_two_dates(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(19,12, 31), date(20,7,1),_,_Final_value).
test(0) :-
	depreciation_between_two_dates(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(19,7, 1), date(21,7,1),diminishing_value,_Final_value).
test(0) :-
	depreciation_between_two_dates(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(100, 0)), date(19,12, 31), date(20,7,1),diminishing_value,_Final_value).
*/
:- end_tests(depreciation).
:- run_tests.

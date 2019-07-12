
% Calculates depreciation on a daily basis between the invest in date and any other date
% recurses for every year, because depreciation rates may be different
depreciation_between_invest_in_date_and_other_date(
	Invest_in_value, Initial_value, Method, date(From_year, From_Month, From_day), To_date,
	Account, Depreciation_year, By_day_factor, Total_depreciation_value
	) :-
	day_diff(date(From_year, From_Month, From_day), To_date, Days_difference),
	Days_difference >= 0,
	depreciation_rate(Account, Depreciation_year, Depreciation_rate),
	Depreciation_fixed_value = Invest_in_value * Depreciation_rate,
	(Days_difference =< 365 -> depreciation_by_method(Method, Initial_value, Depreciation_rate, Depreciation_fixed_value, By_day_factor,
		Days_difference, Total_depreciation_value);
	(
	depreciation_by_method(Method, Initial_value, Depreciation_rate, Depreciation_fixed_value, By_day_factor, 365, Depreciation_value),
	Next_depreciation_year is Depreciation_year + 1,
	Next_from_year is From_year + 1,
	Next_initial_value is Initial_value - Depreciation_value,
	depreciation_between_invest_in_date_and_other_date(Invest_in_value, Next_initial_value, Method, date(Next_from_year, From_Month, From_day), To_date, 
		Account, Next_depreciation_year, By_day_factor, Next_depreciation_value),
	Total_depreciation_value is  Depreciation_value + Next_depreciation_value
	)).

% Calculates depreciation between any two dates on a daily basis equal or posterior to the invest in date
depreciation_between_two_dates(Transaction, From_date, To_date, Method, Depreciation_value):-
	day_diff(From_date, To_date, Days_difference),
	Days_difference >= 0,
	written_down_value(Transaction, To_date, Method, To_date_written_down_value),
	written_down_value(Transaction, From_date, Method, From_date_written_down_value),
	Depreciation_value is From_date_written_down_value - To_date_written_down_value.

% Calculates written down value at a certain date equal or posterior to the invest in date using a daily basis
written_down_value(Transaction, Written_down_date, Method, Written_down_value):-
	transaction_cost(Transaction, Cost),
	transaction_date(Transaction, Invest_in_date),
	transaction_account(Transaction, Account),
	depreciation_between_invest_in_date_and_other_date(Cost, Cost, Method, Invest_in_date, Written_down_date, Account, 1, 1/365, Total_depreciation_value),
	Written_down_value is Cost - Total_depreciation_value.


/* There are 2 methods used for depreciation. a. Diminishing Value. What I believe you implemented. i.e. Rate 20% per period, 
Cost 100, then at end of period 1, Written Down Value is 100-20. For Period 2, 20%*80, For Period 3 20%*64 ... of course, 
written down value never gets to zero.

And there is Prime Cost Method. 20% of Cost each period. i.e. 100-20=80. 80-20=60, 60-20=40..... to zero.

And there is another concept to consider. If the asset (say a car) is depreciated to some value at some point in time, 
say $20. And the car is sold for $40, then there is a gain of $20. But if it is sold for $10, then there is a loss of $10. */

depreciation_by_method(Method, Initial_value, Depreciation_rate, Depreciation_fixed_value, By_day_factor, Days, Depreciation_value):-
	Factor is By_day_factor * Days,
	(Method == diminishing_value -> 
		Depreciation_value is Factor * Initial_value * Depreciation_rate
		;
		Depreciation_value is Factor * Depreciation_fixed_value).

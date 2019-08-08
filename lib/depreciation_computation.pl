
:- module(depreciation_computation, [
		written_down_value/5, 
		depreciation_between_two_dates/6, 
		transaction_account/2, 
		transaction_cost/2, 
		transaction_date/2]).


:- use_module(days, [day_diff/3]).
:- use_module(utils, [throw_string/1]).


% Calculates depreciation on a daily basis between the invest in date and any other date
% recurses for every year, because depreciation rates may be different
depreciation_between_invest_in_date_and_other_date(
	Invest_in_value, 						% value at time of investment
	Initial_value, 							% value at start of year
	Method, 
	date(From_year, From_Month, From_day),	% date of investment
	To_date,								% date for which depreciation should be computed
	Account,
	Rates,
	Depreciation_year, 						% it doesn't seem that we're actually making use of this.
	By_day_factor, 							% 1/(days per depreciation period)
	Total_depreciation_value
) :-
	/*format(user_error, depreciation_between_invest_in_date_and_other_date,[]),*/
	day_diff(date(From_year, From_Month, From_day), To_date, Days_difference),
	check_day_difference_validity(Days_difference),	
	
	% throw exception 
	% if we do not have depreciation rate for the specific year we are looking for or
	% if there is no depreciation rate with unbound variable for depreciation year
	copy_term(Rates, Rates_Copy),
	(	
	member(depreciation_rate(Account, Depreciation_year, Depreciation_rate), Rates_Copy)
	->
		true
	;
		throw_string('Expected depreciation rate not found.')		
	),
		
	/*format(user_error, "ok..\n", []),*/

	% amount of depreciation in the first depreciation period.
	Depreciation_fixed_value = Invest_in_value * Depreciation_rate,
	(
			% if we're hard-coding the assumption that the depreciation period is 1 year
			% then we can hard-code the "by day factor" as 1/365 and don't need to pass it around.
			% but we should perhaps instead generalize to handle arbitrary periods.
			Days_difference =< 365 
	-> 		depreciation_by_method(
				Method, 
				Initial_value, 
				Depreciation_rate, 
				Depreciation_fixed_value, 
				By_day_factor,
				Days_difference, 
				Total_depreciation_value
			)
	;
		(
			depreciation_by_method(
				Method, 
				Initial_value, 
				Depreciation_rate, 
				Depreciation_fixed_value, 
				By_day_factor, 
				365, 
				Depreciation_value
			),
			Next_depreciation_year is Depreciation_year + 1,
			Next_from_year is From_year + 1,
			Next_initial_value is Initial_value - Depreciation_value,
			depreciation_between_invest_in_date_and_other_date(
				Invest_in_value, 
				Next_initial_value, 
				Method, 
				date(Next_from_year, From_Month, From_day), 
				To_date, 
				Account,
				Rates, 
				Next_depreciation_year, 
				By_day_factor, 
				Next_depreciation_value
			),
			Total_depreciation_value is  Depreciation_value + Next_depreciation_value
		)
	).

% Calculates depreciation between any two dates on a daily basis equal or posterior to the invest in date
depreciation_between_two_dates(Transaction, From_date, To_date, Method, Rates, Depreciation_value):-
	day_diff(From_date, To_date, Days_difference),
	check_day_difference_validity(Days_difference),
	written_down_value(Transaction, To_date, Method, Rates, To_date_written_down_value),
	written_down_value(Transaction, From_date, Method, Rates, From_date_written_down_value),
	Depreciation_value is From_date_written_down_value - To_date_written_down_value.

% Calculates written down value at a certain date equal or posterior to the invest in date using a daily basis
written_down_value(Transaction, Written_down_date, Method, Rates, Written_down_value):-
	transaction_cost(Transaction, Cost),
	transaction_date(Transaction, Invest_in_date),
	transaction_account(Transaction, Account),
	depreciation_between_invest_in_date_and_other_date(
		Cost, 
		Cost, 
		Method, 
		Invest_in_date, 
		Written_down_date, 
		Account, 
		Rates,
		1,/* i guess this is in the sense of first year of ownership*/
		1/365, 
		Total_depreciation_value
	),
	Written_down_value is Cost - Total_depreciation_value.


/* There are 2 methods used for depreciation. a. Diminishing Value. What I believe you implemented. i.e. Rate 20% per period, 
Cost 100, then at end of period 1, Written Down Value is 100-20. For Period 2, 20%*80, For Period 3 20%*64 ... of course, 
written down value never gets to zero.

And there is Prime Cost Method. 20% of Cost each period. i.e. 100-20=80. 80-20=60, 60-20=40..... to zero.

And there is another concept to consider. If the asset (say a car) is depreciated to some value at some point in time, 
say $20. And the car is sold for $40, then there is a gain of $20. But if it is sold for $10, then there is a loss of $10. */


depreciation_by_method(
	Method, 					% depreciation method: (diminishing value | prime cost)
	Initial_value, 				% value at end of previous depreciation period
	Depreciation_rate, 			% rate per depreciation-period
	Depreciation_fixed_value, 	% Original investment value * depreciation rate
	By_day_factor, 				% 1/(days per depreciation-period)
	Days, 						% number of days elapsed
	Depreciation_value			% value at end of current fractional depreciation period
):-
	/*format(user_error, "ok..\n", []),*/

	% Factor is the fraction of a depreciation period represented by Days
	Factor is By_day_factor * Days, 
	(
		% this is more like applying diminishing value method for integer number of depreciation periods
		% but applying prime cost method for fractions of a depreciation period
		% actual formula would be:
		% Depreciation_value is Initial_value - (Initial_value * (1 - Depreciation_rate)^Factor)
		% or:
		% Depreciation_value is Initial_value * (1 - (1 - Depreciation_rate)^Factor)
		Method == diminishing_value 
	-> 	Depreciation_value is Factor * Initial_value * Depreciation_rate
	;
		% if computed depreciation value is > initial value, then actual depreciation value = initial value.
		% assuming the asset can't depreciate by more than it's worth.
		Depreciation_value is Factor * Depreciation_fixed_value
	).
	

% if days difference is less than zero, it means that the requested date 
% in the input value is earlier than the invest in date.
check_day_difference_validity(Days_difference) :-
	(
	Days_difference >= 0
	->
		true
	;
		throw_string('Request date is earlier than the invest in date.')
	).


/*
standalone calc should probably take transaction terms as input, but it can pretty much just return the calculated values
*/

% Predicates for asserting that the fields of given transactions have particular values
% duplicated from transactions.pl with the difference that transaction_date is used instead of transaction_day
% ok well transactions.pl transactions now use date too, just havent renamed it yet, so we can probably use it 
% The absolute day that the transaction happenned
% ok well transactions.pl uses dates, not days
% input and output xml should use dates too, so idk, best to convert it to days just inside the computation functions and convert it back after
transaction_date(transaction(Date, _, _, _), Date).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account(transaction(_, _, Account_Id, _), Account_Id).
% The amounts by which the account is being debited and credited
transaction_vector(transaction(_, _, _, Vector), Vector).
% Extract the cost of the buy from transaction data
transaction_cost(transaction(_, _, _, t_term(Cost, _)), Cost).



% The purpose of the following program is to define modular dates, a generalization of
% Gregorian dates where the day and month can take on any integral value. They allow you
% to do things like specify a date relative to the end of a month, add a month to it and
% get a date relative to the end of the next month. The program also defines absolute
% days, the number of days since since 1st January 2001. And accordingly it provides
% relations to convert from modular dates to absolute days.

% This program is a part of a larger system for deriving various pieces of information on
% different financial arrangements, hire purchase arrangements being an example. This
% larger system uses absolute days to represent time internally because they are easier
% to manipulate with than Gregorian dates.

% Some facts about the Gregorian calendar, needed to count days between dates

leap_year(Year) :- 0 is mod(Year, 4), X is mod(Year, 100), X =\= 0.

leap_year(Year) :- 0 is mod(Year, 400).

common_year(Year) :-
	((Y is mod(Year, 4), Y =\= 0); 0 is mod(Year, 100)),
	Z is mod(Year, 400), Z =\= 0.

days_in(_, 1, 31). days_in(Year, 2, 29) :- leap_year(Year).
days_in(Year, 2, 28) :- common_year(Year). days_in(_, 3, 31). days_in(_, 4, 30).
days_in(_, 5, 31). days_in(_, 6, 30). days_in(_, 7, 31). days_in(_, 8, 31).
days_in(_, 9, 30). days_in(_, 10, 31). days_in(_, 11, 30). days_in(_, 12, 31).

days_in(Year, Month, Days) :-
	Month =< 0,
	Closer_Year is Year - 1,
	Closer_Year_Month is 12 + Month,
	days_in(Closer_Year, Closer_Year_Month, Days).

days_in(Year, Month, Days) :-
	Month > 12,
	Closer_Year is Year + 1,
	Closer_Year_Month is Month - 12,
	days_in(Closer_Year, Closer_Year_Month, Days).

% A generalized date, date(Y, M, D), means the same thing as a normal date when its value
% is that of a normal date. In addition date(2006, 0, 1) refers to the month before
% date(2006, 1, 1), date(2006, -1, 1) to the month before that, etc. Also date(2006, 5, 0)
% refers to the day before date(2006, 5, 1), date(2006, 5, -1) to the day before that,
% etc. Months have precedence over days. Useful for specifying that payments happen at
% month-ends.

% Predicates for counting the number of days between two generalized dates

day_diff(date(Year, From_Month, From_Day), date(Year, To_Month, To_Day), Days) :-
	From_Month < To_Month,
	New_To_Month is To_Month - 1,
	days_in(Year, New_To_Month, New_To_Month_Days),
	New_To_Day is To_Day + New_To_Month_Days,
	day_diff(date(Year, From_Month, From_Day), date(Year, New_To_Month, New_To_Day), Days), !.

day_diff(date(Year, From_Month, From_Day), date(Year, To_Month, To_Day), Days) :-
	To_Month < From_Month,
	days_in(Year, To_Month, To_Month_Days),
	New_To_Month is To_Month + 1,
	New_To_Day is To_Day - To_Month_Days,
	day_diff(date(Year, From_Month, From_Day), date(Year, New_To_Month, New_To_Day), Days), !.

day_diff(date(From_Year, From_Month, From_Day), date(To_Year, To_Month, To_Day), Days) :-
	From_Year =\= To_Year,
	New_To_Month is To_Month + 12 * (To_Year - From_Year),
	day_diff(date(From_Year, From_Month, From_Day), date(From_Year, New_To_Month, To_Day), Days), !.

day_diff(date(Year, Month, From_Day), date(Year, Month, To_Day), Diff) :-
	Diff is To_Day - From_Day.

% Internal representation for dates is absolute day count since 1st January 2001

absolute_day(Date, Day) :- day_diff(date(2000, 1, 1), Date, Day).


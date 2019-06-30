% ===================================================================
% Project:   LodgeiT
% Module:    days.pl
% Date:      2019-06-02
% ===================================================================

:- module(days, [absolute_day/2,
		 date_add/3,
		 day_between/3,
		 format_date/2,
		 parse_date/2,
		 gregorian_date/2,
		 add_days/3]).

	
% -------------------------------------------------------------------
% The purpose of the following program is to define modular dates, a generalization of
% Gregorian dates where the day and month can take on any integral value. They allow you
% to do things like specify a date relative to the end of a month, add a month to it and
% get a date relative to the end of the next month. The program also defines absolute
% days, the number of days since since 1st January 2001. And accordingly it provides
% relations to convert from modular dates to absolute days.
%
% This program is a part of a larger system for deriving various pieces of information on
% different financial arrangements, hire purchase arrangements being an example. This
% larger system uses absolute days to represent time internally because they are easier
% to manipulate with than Gregorian dates.
/*
we may want to review this, debugging is harder with absolute days.
*/
%
% Some facts about the Gregorian calendar, needed to count days between dates
%---------------------------------------------------------------------

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


% -------------------------------------------------------------------
% A generalized date, date(Y, M, D), means the same thing as a normal date when its value
% is that of a normal date. In addition date(2006, 0, 1) refers to the month before
% date(2006, 1, 1), date(2006, -1, 1) to the month before that, etc. Also date(2006, 5, 0)
% refers to the day before date(2006, 5, 1), date(2006, 5, -1) to the day before that,
% etc. Months have precedence over days. Useful for specifying that payments happen at
% month-ends.
% -------------------------------------------------------------------

date_add(date(A, B, C), date(D, E, F), date(G, H, I)) :-
	G is A + D,
	H is B + E,
	I is C + F.


% -------------------------------------------------------------------
% The following predicate relates a date to which day it is in the year
% -------------------------------------------------------------------

year_day(date(_, 1, Day), Day).

year_day(date(Year, Month, Day), Year_Day) :-
	Month > 1,
	Prev_Month is Month - 1,
	year_day(date(Year, Prev_Month, 1), Day_A),
	days_in(Year, Prev_Month, Day_B),
	Year_Day is Day_A + Day - 1 + Day_B.

year_day(date(Year, Month, Day), Year_Day) :-
	Month < 1,
	Next_Month is Month + 1,
	year_day(date(Year, Next_Month, 1), Day_A),
	days_in(Year, Month, Day_B),
	Year_Day is Day_A + Day - 1 - Day_B.


% -------------------------------------------------------------------
% The following predicate relates a year day to its month and month day
% -------------------------------------------------------------------

month_day(Year, Year_Day, Month, Month_Day) :-
	Month_Lower is ((Year_Day - 1) div 31) + 1, % Lowest possible month for given day
	Month_Upper is ((Year_Day - 1) div 28) + 1, % Highest possible month for given day
	between(Month_Lower, Month_Upper, Month), % The right month is somewhere between
	year_day(date(Year, Month, 1), Month_Start_Year_Day),
	days_in(Year, Month, Month_Length),
	Month_End_Year_Day is Month_Start_Year_Day + Month_Length - 1,
	Month_Start_Year_Day =< Year_Day, Year_Day =< Month_End_Year_Day,
	Month_Day is Year_Day + 1 - Month_Start_Year_Day.


% -------------------------------------------------------------------
% Internal representation for dates is absolute day count since 1st January 0001
% -------------------------------------------------------------------

absolute_day(date(Year, Month, Day), Abs_Day) :-
	Month_A is (Year - 1) * 12 + (Month - 1),
	Num_400Y is Month_A div (400 * 12),
	Num_100Y is Month_A div (100 * 12),
	Num_4Y is Month_A div (4 * 12),
	Num_1Y is Month_A div (1 * 12),
	Years_Day is (Num_1Y * 365) + (Num_4Y * 1) - (Num_100Y * 1) + (Num_400Y * 1),
	Month_B is 1 + (Month_A mod 12),
	year_day(date(Num_1Y + 1, Month_B, Day), Year_Day),
	Abs_Day is Years_Day + Year_Day.

gregorian_date(Abs_Day, date(Year, Month, Day)) :-
	Days_1Y is 365,
	Days_4Y is (4 * Days_1Y) + 1,
	Days_100Y is (25 * Days_4Y) - 1,
	Days_400Y is (4 * Days_100Y) + 1,
	Num_400Y is (Abs_Day - 1) div Days_400Y,
	Num_100Y is ((Abs_Day - 1) mod Days_400Y) div Days_100Y,
	Num_4Y is (((Abs_Day - 1) mod Days_400Y) mod Days_100Y) div Days_4Y,
	Num_1Y is ((((Abs_Day - 1) mod Days_400Y) mod Days_100Y) mod Days_4Y) div Days_1Y,
	Year_Day is 1 + (((((Abs_Day - 1) mod Days_400Y) mod Days_100Y) mod Days_4Y) mod Days_1Y),
	Year is 1 + (400 * Num_400Y) + (100 * Num_100Y) + (4 * Num_4Y) + (1 * Num_1Y),
	month_day(Year, Year_Day, Month, Day).


% -------------------------------------------------------------------
% Predicate asserts that the given absolute day resides between two Gregorian dates
% -------------------------------------------------------------------

day_between(Opening_Date, Closing_Date, Day) :-
	absolute_day(Opening_Date, Opening_Day),
	absolute_day(Closing_Date, Closing_Day),
	Opening_Day =< Day, Day < Closing_Day.


% -------------------------------------------------------------------
% parses date in "DD-MM-YYYY" format
% -------------------------------------------------------------------

parse_date(DateString, YMD) :-
   parse_time(DateString, iso_8601, UnixTimestamp),
   stamp_date_time(UnixTimestamp, DateTime, 'UTC'), 
   date_time_value(date, DateTime, YMD).

format_date(Date, DateString) :-
   format_time(string(DateString), '%Y-%m-%d', Date).


   

add_days(Date, Absolute_Days, Date2) :-
	absolute_day(Date, Day),
	Day2 is Day + Absolute_Days,
	gregorian_date(Day2, Date2).

	

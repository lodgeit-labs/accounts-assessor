:- module(theory_date, [date_constraints/1]).
:- use_module(library(chr)).
:- chr_constraint
	fact/3,
	rule/0.

% The date theory is special...

:- multifile chr_fields/2.

chr_fields(date, [
	_{
		key:year,
		type:integer,
		unique:true,
		required:true
	},
	_{
		key:month,
		type:integer, % type should actually be something that actually represents a specific month object, so that we can do like self.month.length
		unique:true,
		required:true
	},
	_{
		key:day,
		type:integer, 
		unique:true,
		required:true
	},
	_{
		key:day_of_week,
		type:integer,
		unique:true,
		required:true
	}
]).


day_number(1,"Sunday").
day_number(2,"Monday").
day_number(3,"Tuesday").
day_number(4,"Wednesday").
day_number(5,"Thursday").
day_number(6,"Friday").
day_number(7,"Saturday").

month_number("January",   1).
month_number("February",  2).
month_number("March",     3).
month_number("April",     4).
month_number("May",       5).
month_number("June",      6).
month_number("July",      7).
month_number("August",    8).
month_number("September", 9).
month_number("October",  10).
month_number("November", 11).
month_number("December", 12).

date_constraints(Date) :-
	Date = date{
		year:Year,
		year_length:Year_Length,
		month:Month,
		month_length:Month_Length,
		month_name:Month_Name,
		day:Day,
		day_of_week:Day_Of_Week,
		julianpl_day_of_week:_JulianPL_Day_Of_Week,
		day_of_week_name:Day_Of_Week_Name,
		leap_year:Leap_Year,
		february_length:February_Length,
		leap_cycle_number:Leap_Cycle_Number,
		leap_cycle_offset_years:Leap_Cycle_Offset_Years,
		leap_cycle_offset_days:Leap_Cycle_Offset_Days,
		leap_cycle_offset_100yr_days:Leap_Cycle_Offset_100Yr_Days,
		century_number:Century_Number,
		century_offset_years:Century_Offset_Years,
		century_offset_4yr_days:Century_Offset_4Yr_Days,
		leap_number:Leap_Number,
		leap_offset_years:Leap_Offset_Years,
		leap_offset_1yr_days:Leap_Offset_1Yr_Days,
		year_offset_1mo_days:Year_Offset_1Mo_Days,
		previous_month_lengths:Previous_Month_Lengths_This_Year
	},
	Months = [
		[1,		31,					"January"], % why can't "January" be an integer? :)
		[2,		February_Length,	"February"],
		[3,		31, 				"March"],
		[4,		30, 				"April"],
		[5,		31, 				"May"],
		[6,		30, 				"June"],
		[7,		31, 				"July"],
		[8,		31, 				"August"],
		[9,		30, 				"September"],
		[10,	31, 				"October"],
		[11,	30, 				"November"],
		[12,	31, 				"December"]
	],

	maplist([[_,X,_],X]>>(true),Months,Month_Lengths),
	convlist([[X,Y,_],[X,Y]]>>(X \= 2),Months,Month_Integer_Values),
	%maplist([[_,_,X],X]>>(true),Months,Month_Names),
	%maplist([[_,X],X]>>(true),Days_Of_Week,Days_Of_Week_Names),
	Month in 1..12,
	Day_Of_Week in 1..7,
	when(nonvar(Month), month_number(Month_Name, Month)),
	when(nonvar(Month_Name), month_number(Month_Name, Month)),
	when(nonvar(Day_Of_Week), day_number(Day_Of_Week,Day_Of_Week_Name)),
	when(nonvar(Day_Of_Week_Name), day_number(Day_Of_Week,Day_Of_Week_Name)),

	Day #>= 1,
	Day #=< Month_Length,

	sum(Month_Lengths, #=, Year_Length),

	February_Length #= 28 + Leap_Year,
	tuples_in([[Month, Month_Length]], Month_Integer_Values) #\ ((Month #=2) #/\ (Month_Length #= February_Length)),

	(Year mod 400 #= 0) #\/ ((Year mod 4 #= 0) #/\ (Year mod 100 #\= 0)) #<==> Leap_Year,
	Leap_Year #<==> (February_Length #= 29),
	Leap_Year #\ (February_Length #= 28),


	
	% DAY OF THE WEEK:
	% 
	% This is all for calculating Day_Of_Week, pretty much the most complex part but the logic is basically straightforward	
	% The reference point is Jan 1st, 0 AD (same as 1 BC)
	% 
	% This gives us bidirectionality, but it's not declarative!

	Year // 400 #= Leap_Cycle_Number,							% which 400-year leap cycle
	Year mod 400 #= Leap_Cycle_Offset_Years,					% how many years into the 400-year leap cycle
	Leap_Cycle_Offset_Years // 100 #= Century_Number,			% which century in the 400-year leap cycle
	Leap_Cycle_Offset_Years mod 100 #= Century_Offset_Years,	% how many years into that century
	Century_Offset_Years // 4 #= Leap_Number,					% which leap round (4-year interval) in that century
	Century_Offset_Years mod 4 #= Leap_Offset_Years,			% how many years into that leap round

	% then we translate these offsets into days and add them up to get the total offset in days into this 400-year leap cycle
	% The total number of days in a 400-year cycle is divisible by 7 so we just add this offset to the day-of-week index of the reference point
	Leap_Cycle_Offset_Days #= Leap_Cycle_Offset_100Yr_Days + Century_Offset_4Yr_Days + Leap_Offset_1Yr_Days + Year_Offset_1Mo_Days + Day - 1,
	Day_Of_Week #= ((Leap_Cycle_Offset_Days - 1) mod 7) + 1, % +1 and -1 is correcting the offset of the day of week index, 7 is the index of Saturday,



	% Then code to calculate how many days in each sub-offset (the complicated part):

	% Case when "century number" is 0, i.e. 1st century of the 400 year leap cycle
	(Century_Number #= 0) #<==> (Leap_Cycle_Offset_100Yr_Days #= 0),
	(Century_Number #= 0) #==> (Century_Offset_4Yr_Days #= (366 + 365*3)*Leap_Number),
	((Century_Number #= 0) #/\ (Leap_Offset_Years #= 0))
	#==> (	(Leap_Offset_1Yr_Days #= 0)
	),

	((Century_Number #= 0) #/\ (Leap_Offset_Years #> 0))
	#==> (
			(Century_Offset_4Yr_Days #= (366 + 365*3) * Leap_Number)
	#/\		(Leap_Offset_1Yr_Days #= (366 + (Leap_Offset_Years - 1) * 365))
	),
		

	% Case when "century number" > 0, i.e. the other centuries in the 400 year leap cycle
	(Century_Number #>0) #<==> (Leap_Cycle_Offset_100Yr_Days #= 36525 + (Century_Number - 1)*36524),
	((Century_Number #> 0) #/\ (Leap_Number #= 0) #/\ (Leap_Offset_Years #> 0))
	#==> (
	 	(Leap_Offset_1Yr_Days #= 365*Leap_Offset_Years)
	),

	((Century_Number #> 0) #/\ (Leap_Number #> 0)) #==> (Century_Offset_4Yr_Days #= 1460 + (Leap_Number - 1)*1461), 
	((Century_Number #> 0) #/\ (Leap_Number #> 0) #/\ (Leap_Offset_Years #> 0))
	#==> (
		(Leap_Offset_1Yr_Days #= 366 + (Leap_Offset_Years - 1)*365)
	),


	(Leap_Offset_Years #= 0) #<==> (Leap_Offset_1Yr_Days #= 0),
	(Leap_Number #= 0) #<==> (Century_Offset_4Yr_Days #= 0),



	% Year_Offset_1Mo_Days = How many days in previous months this year:
	when(nonvar(Month), convlist([[X,Y,_],Y]>>(X < Month), Months, Previous_Month_Lengths_This_Year)),
	when(ground(Previous_Month_Lengths_This_Year), sum(Previous_Month_Lengths_This_Year, #=, Year_Offset_1Mo_Days)),




	
	% package(julian) code
	% just pulled from that codebase so that the constraints can be applied whenever Year is within the appropriate range
	% rather than failing whenever it isn't

	% these don't happen to need to apply to any particular Year range
	% Open question: are these equivalent to the rules above?
	(   (Day in 1..28)
    #\/ (Month #\= 2 #/\ Day in 29..30)
    #\/ (Month in 1 \/ 3 \/ 5 \/ 7 \/ 8 \/ 10 \/ 12 #/\ Day #= 31)
    #\/ (Month #= 2 #/\ Day #= 29 #/\ Year mod 400 #= 0)
    #\/ (Month #= 2 #/\ Day #= 29 #/\ Year mod 4 #= 0 #/\ Year mod 100 #\= 0)
    ),

	% Open question: I have no idea how these constraints work, maybe some kind of approximation magic and possible that these
	% rules actually don't apply outside this range.
	(Year in -4712 .. 3267)	
	#==> (
			JulianPL_Day_Of_Week #= (Day_Of_Week - 2) mod 7
	#/\		JulianPL_Day_Of_Week #= (MJD+2) mod 7 % MJD has 0 as Wednesday; Day_Of_Week + 3 
	#/\		MJD in -2400328 .. 514671
	#/\		E #= 4 * ((194800*MJD+467785976025)//194796) + 3
	#/\		H #= mod(E, 1461)//4*5 + 2
   	#/\		Day #= mod(H, 153)//5 + 1
    #/\		Month #= mod(H//153+2, 12) + 1
    #/\		Year #= E//1461 + (14 - Month)//12 - 4716
	).

test(0) :-
	% input:
	date_constraints(Date),
	Date.year #= Year,
	Date.month #= 7,
	Date.day #= 4,
	Year in 1953..1961,
	Date.day_of_week #= 1,

	% result:
	Year == 1954.

test(1) :-
	% input:
	date_constraints(Date),
	Date.year #= 2000,
	Date.month #= 2,
	fd_sup(Date.day, February_Length),
	
	% result:
	February_Length == 29.

test(2) :-
	% input:
	date_constraints(Date),
	Date.year #= 2000,
	Date.month #= 3,
	fd_sup(Date.day, March_Length),
	
	% result:
	March_Length == 31.

test(3) :-
	% input:
	date_constraints(Date),
	Date.year #= 2020,
	Date.month #= 2,
	Date.day #= 20,

	% result:
	Date.day_of_week_name == "Thursday".

test(4) :-
	%input:
	date_constraints(Date),
	Date.year #= Year,
	Date.month #= 2,
	Date.day #= 29,
	Year in 1998..2002,
	
	% result:
	Year == 2000.

test(5) :-
	% input:
	date_constraints(Date),
	% this is essentially the "origin" of the Gregorian coordinate system
	Date.year = 0,
	Date.month = 1,
	Date.day = 1,

	% result: the world began on saturday
	Date.day_of_week_name == "Saturday".

test(6) :-
	date_constraints(Date),
	Date.year = Year,
	Date.month_name = "July",
	Date.day = 4,
	Year in 1953..1961,
	Date.day_of_week_name = "Sunday",

	% result:
	Year == 1954.

	

run_test(N) :-
	(
		test(N)
	->	format(user_error, "Test ~w -- good~n", [N])
	;	format(user_error, "Test ~w -- FAIL~n", [N])
	).

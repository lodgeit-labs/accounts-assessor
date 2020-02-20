:- use_module(library(clpfd)).
%:- use_module(library(julian)).
%:- use_module(library(error), []).
%:- use_module(library(typedef)).
%:- use_module(library(when), [when/2]).
%:- use_module(library(dcg/basics), [float//1, integer//1, string//1]).
%:- use_module(library(list_util), [xfy_list/3]).
%:- use_module(library(delay), [delay/1]).



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
		[1,31,"January"], % why can't "January" be an integer? :)
		/*[2,28],[2,29],*/
		[2,February_Length, "February"],
		[3,31, "March"],
		[4,30, "April"],
		[5,31, "May"],
		[6,30, "June"],
		[7,31, "July"],
		[8,31, "August"],
		[9,30, "September"],
		[10,31, "October"],
		[11,30, "November"],
		[12,31, "December"]
	],

	Days_Of_Week = [
		[1,"Sunday"],
		[2,"Monday"],
		[3,"Tuesday"],
		[4,"Wednesday"],
		[5,"Thursday"],
		[6,"Friday"],
		[7,"Saturday"]
	],
	maplist([[_,X,_],X]>>(true),Months,Month_Lengths),
	convlist([[X,Y,_],[X,Y]]>>(X \= 2),Months,Month_Integer_Values),
	maplist([[_,_,X],X]>>(true),Months,Month_Names),
	maplist([[_,X],X]>>(true),Days_Of_Week,Days_Of_Week_Names),
	Month in 1..12,
	Day_Of_Week in 1..7,
	when(nonvar(Month), nth1(Month, Month_Names, Month_Name)),
	when(nonvar(Day_Of_Week), nth1(Day_Of_Week, Days_Of_Week_Names, Day_Of_Week_Name)),

	Day #>= 1,
	Day #=< Month_Length,

	sum(Month_Lengths, #=, Year_Length),

	February_Length #= 28 + Leap_Year,
	tuples_in([[Month, Month_Length]], Month_Integer_Values) #\ ((Month #=2) #/\ (Month_Length #= February_Length)),

	(Year mod 400 #= 0) #\/ ((Year mod 4 #= 0) #/\ (Year mod 100 #\= 0)) #<==> Leap_Year,
	Leap_Year #<==> (February_Length #= 29),
	Leap_Year #\ (February_Length #= 28),

	
	Year // 400 #= Leap_Cycle_Number,
	Year mod 400 #= Leap_Cycle_Offset_Years,
	Leap_Cycle_Offset_Years // 100 #= Century_Number,
	Leap_Cycle_Offset_Years mod 100 #= Century_Offset_Years,
	Century_Offset_Years // 4 #= Leap_Number,
	Century_Offset_Years mod 4 #= Leap_Offset_Years,

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
	
	when(nonvar(Month), convlist([[X,Y,_],Y]>>(X < Month), Months, Previous_Month_Lengths_This_Year)),
	when(ground(Previous_Month_Lengths_This_Year), sum(Previous_Month_Lengths_This_Year, #=, Year_Offset_1Mo_Days)),
	Leap_Cycle_Offset_Days #= Leap_Cycle_Offset_100Yr_Days + Century_Offset_4Yr_Days + Leap_Offset_1Yr_Days + Year_Offset_1Mo_Days + Day - 1,

	Day_Of_Week #= ((Leap_Cycle_Offset_Days - 1) mod 7) + 1, % +1 and -1 is correcting the offset of the day of week index, 7 is the index of Saturday,

	
	% apply the special constraints from package(julian) whenever the Year is within the appropriate range
	(   (Day in 1..28)
    #\/ (Month #\= 2 #/\ Day in 29..30)
    #\/ (Month in 1 \/ 3 \/ 5 \/ 7 \/ 8 \/ 10 \/ 12 #/\ Day #= 31)
    #\/ (Month #= 2 #/\ Day #= 29 #/\ Year mod 400 #= 0)
    #\/ (Month #= 2 #/\ Day #= 29 #/\ Year mod 4 #= 0 #/\ Year mod 100 #\= 0)
    ),

	% I have no idea how these constraints work, maybe some kind of approximation magic
	%(Year #>= -4712) #/\ (Year #=< 3267)
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

:- chr_constraint
	fact/3,
	rule/0.

% The date theory is special...

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

chr_fields(list, [
	_{
		key:length,
		type:integer,
		required:true
	},
	_{
		key:element_type,
		/* type should be type but let's not go there right now */
		unique:true /* just because for now we don't have any interpretation of a list with multiple element types */
	},
	_{
		key:first,
		/*can we make this theory work over regular rdf list representation? (i.e. no distinction between lists and list-cells) */
		type:list_cell,
		unique:true
		/*required:false % existence is dependent on length, exists exactly when length is non-zero / list is non-empty */
	},
	_{
		key:last,
		type:list_cell,
		unique:true
		/*required:false % existence is dependent on length, exists exactly when length is non-zero / list is non-empty */
	}
]).

chr_fields(list_cell, [
	_{
		key:value,
		/* type: self.list.element_type */
		unique:true,
		required:true
	},
	_{
		key:list,
		type:list,
		unique:true,
		required:true
	},
	_{
		key:index,
		type:integer,
		unique:true,
		required:true	
	},
	_{
		key:next,
		type:list_cell,
		unique:true
		/* required: false % exists exactly when this is not the last element */
	},
	_{
		key:previous,
		type:list_cell,
		unique:true
		/* required: false % exists exactly when this is not the first element */
	}
]).

chr_fields(hp_arrangement, [
	_{
		key:begin_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:end_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:cash_price,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:interest_rate,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:repayment_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:number_of_installments,
		type:integer,
		unique:true,
		required:true
	},
	_{
		key:final_balance,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:installments,
		type:list(hp_installment),
		unique:true,
		required:true
	}
]).


chr_fields(hp_installment, [
	/*
	_{
		key:hp_arrangement,
		type:hp_arrangement,
		unique:true,
		required:true
	},
	*/
	_{
		key:number,
		type:integer,
		unique:true,
		required:true
	},
	_{
		key:opening_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:opening_balance,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:payment_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:interest_rate,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:interest_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:closing_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:closing_balance,
		type:rational,
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
		[1,		31,					'foo'], % why can't "January" be an integer? :)
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


% HP ARRANGEMENTS & HP INSTALLMENTS THEORY

% HP ARRANGEMENT GLOBAL CONSTRAINTS
	fact(HP, a, hp_arrangement)
	\
	rule
	<=>
	\+find_fact(rule1, fired_on, [fact(HP, a, hp_arrangement)])
	|
	fact(rule1, fired_on, [fact(HP, a, hp_arrangement)]),
	add_constraints([

	% relate HP parameters to first and last installments
	% Note that all of these HP parameters are redundant and just referencing values at the endpoints of the HP installments "curve"
	% this assumes that an installment necessarily exists.
	First_Installment 			= HP:installments:first:value,
	Last_Installment 			= HP:installments:last:value,
	HP:cash_price 				= First_Installment:opening_balance,
	HP:begin_date				= First_Installment:opening_date, /* needs payment type parameter */
	HP:final_balance 			= Last_Installment:closing_balance,
	HP:end_date 				= Last_Installment:closing_date,
	HP:number_of_installments 	= Last_Installment:number,

	% special formula: repayment amount
	% the formula doesn't account for balloons/submarines and other variations
	% these are just giving abbreviated variables to use in the special formula:
	P0 = HP:cash_price,    			% P0 = principal / balance at t = 0
	PN = HP:final_balance, 			% PN = principal / balance at t = N
	IR = HP:interest_rate,
	R = HP:repayment_amount,
	N = HP:number_of_installments,
	{R = (P0 * (1 + (IR/12))^N - PN)*((IR/12)/((1 + (IR/12))^N - 1))}
	]),
	rule.



% CONSTRAINTS ABOUT ANY GIVEN INSTALLMENT:
	fact(HP, a, hp_arrangement),
	fact(HP, has_installment, Installment),
	fact(Installment, list_cell, Installment_Cell) \
	rule
	<=>
	add_constraints([

	% relate installment parameters to HP parameters
	Installment:hp_arrangement		= HP,
	Installment:interest_rate 		= HP:normal_interest_rate,
	Installment:payment_amount 		= HP:normal_payment_amount,		% needs to account for balloon payments


	% relate opening balance, interest rate, interest amount, payment amount, and closing balance
	{Installment:interest_amount 	= Installment:opening_balance * Installment:interest_rate},
	{Installment:closing_balance 	= Installment:opening_balance + Installment:interest_amount - Installment:payment_amount},

	% let the installment object be treated as a list-cell
	Installment_Cell:index 			= Installment:number,
	Installment_Cell:next			= Installment:next,
	Installment_Cell:previous		= Installment:previous,



	/* calculating installment period from index
	% note adding: must be same units; //12 is converting units of months to units of years,
	% with approximation given by rounding down, which is done because the remainder is given
	% as a separate quantity

	 % taking mod in this context requires correction for 0-offset of month-index, ex.. january = 1,
	(year,month) is effectively a kind of compound unit

	% offset is inverse of error
	% 
	*/
	Offset 	#= (HP:begin_month - 1) + (Installment:number - 1), % month's unit and installment index have +1 0-offset, -1 is 0-error (deviation from 0)
	Year 	#= HP:begin_date:year + (Offset // 12),				% note adding: must be same units; //12 is converting units of months to units of years,
	Month	#= ((Offset mod 12) + 1), 							% +1 is return to 0-offset of the month's unit

	% just assuming that the opening date is the 1st of the month and closing date is last of the month
	% Installment:opening_date = date(Year, Month, 1).	% date{year:Year,month:Month,day:1} ?
	Installment:opening_date:year = Year,
	Installment:opening_date:month = Month,
	Installment:opening_date:day = 1,
	Installment:closing_date:year = Year,
	Installment:closing_date:month = Month,
	Installment:closing_date:day = Installment:closing_date:month_length %,
	%Installment:closing_date:day = Month_Length
	]).

	% special formula: closing balance to calculate the closing balance directly from the hp parameters.
	% NOTE: approximation errors in input can cause it to calculate a non-integer installment index
	/*
	P0 = HP.cash_price,
	I = HP.installment_number
	R = HP.repayment_amount
	IR = HP.interest_rate
	PI = P0*(1 + (IR/12))^I - R*((1 + (IR/12))^I - 1)/(IR/12)
	*/



% Constraint relating adjacent installments: continuity principle
% Other constraints are handled by the list theory.
	fact(HP, a, hp_arrangement),
	fact(HP, has_installment, Installment),
	fact(Installment, next, Next_Installment)
	\
	rule
	<=>
	add_constraints([
	Installment:closing_balance = Next_Installment:opening_balance
	]).


% i was holding off on these rules in particular cause i'm trying to patch them into the other rules, where possible
% you can delete it or whatever, i'm just doing it so i can read it now ah sure

/*
% 
% if the cash price is different from the final balance, there must be an installment
% this is really an instance of a more general principle:
% if installment X precedes installment Y, and X.closing_balance \= Y.opening_balance, there must be an installment in between X and Y
% conversely, if there is no installment between X and Y, then X.closing_balance = Y.opening_balance

rule, fact(HP, a, hp_arrangement), fact(HP, cash_price, Cash_Price), fact(HP, final_balance, Final_Balance), fact(HP, installments, Installments) ==> \+find_fact2(_, list_in, Installments1, [Installments1:Installments]), nonvar(Cash_Price), nonvar(Final_Balance), Cash_Price \== Final_Balance | debug(chr_hp, "if the cash price is different from the final balance, there must be an installment.~n", []), fact(_, list_in, Installments).

% this isn't a logical validity it's just a heuristic meant to generate the list when the parameters are underspecified
% if closing balance is greater than or equal to repayment amount, there should be another installment after it
rule, fact(HP, a, hp_arrangement), fact(HP, repayment_amount, Repayment_Amount), fact(HP, installments, Installments), fact(Installment_Cell, list_in, Installments), fact(Installment_Cell, value, Installment), fact(Installment, closing_balance, Closing_Balance) ==> nonvar(Closing_Balance), nonvar(Repayment_Amount), Closing_Balance >= Repayment_Amount, \+find_fact2(Installment_Cell1, next, _, [Installment_Cell1:Installment_Cell]) | debug(chr_hp, "if closing balance is greater than or equal to repayment amount, there should be another installment after it.~n", []), fact(Installment_Cell, next, _).

% this on the other hand is a logical validity:
% if closing balance is not equal to the final balance then there should be another installment after it


% if opening_balance of the installment is less than the cash price of the arrangement, there should be another installment before it
rule, 
	fact(HP, a, hp_arrangement), 
	fact(HP, cash_price, Cash_Price), 
	fact(HP, installments, Installments), 
	fact(Installment_Cell, list_in, Installments), 
	fact(Installment_Cell, value, Installment), 
	fact(Installment, opening_balance, Opening_Balance) 
	==> 
	nonvar(Cash_Price), 
	nonvar(Opening_Balance), 
	Opening_Balance < Cash_Price, 
	\+find_fact2(Installment_Cell1, prev, _, [Installment_Cell1:Installment_Cell]) 
	| 
	debug(chr_hp, "if opening balance is less than the cash price of the arrangement, there should be another installment before it.~n", []), 
	fact(Installment_Cell, prev, _). 

% this is handled by the list theory
% if the index of an installment is the same as the number of installments, then it's the last installment
rule, fact(HP, a, hp_arrangement), fact(HP, number_of_installments, Number_Of_Installments), fact(HP, installments, Installments), fact(Installment, list_in, Installments), fact(Installment, list_index, Number_Of_Installments) ==> fact(Installments, last, Installment).


% if number of installments is nonvar then you can generate all the installments
rule, 
	fact(HP, a, hp_arrangement), 
	fact(HP, number_of_installments, Number_Of_Installments), 
	fact(HP, installments, Installments) 
	==> 
	\+'$enumerate_constraints'(block), 
	nonvar(Number_Of_Installments) 
	| 
	generate_installments(Installments, Number_Of_Installments).
*/


% LIST THEORY
% there is only one cell at any given index
rule,
	fact(L, a, list),
	fact(X, list_in, L),
	fact(X, list_index, I) \
	fact(Y, list_in, L),
	fact(Y, list_index, I)
	<=> 
	add_constraints([
		X = Y
	]).


% if non-empty then first exists, is unique, is in the list, and has list index 1
rule,
	fact(L, a, list),
	fact(_, list_in, L)
	==> 
	add_constraints([
		fact(L, first, _),
		fact(L, last, _)
	]).

% this isn't fully bidirectional: derive first from list-index?
rule,
	fact(L, a, list),
	fact(L, first, First)
	==>
	add_constraints([
		fact(First, list_in, L),
		fact(First, list_index, 1)
	]).


% if non-empty, and N is the length of the list, then last exists, is unique, is in the list, and has list index N
% this isn't fully bidirectional: derive length from list-index of last? derive last from length and list-index?
rule,
	fact(L, a, list),
	fact(L, last, Last),
	fact(L, length, N)
	==> 
	add_constraints([
		fact(Last, list_in, L),
		fact(Last, list_index, N)
	]).

% the list index of any item is between 1 and the length of the list
rule,
	fact(L, a, list),
	fact(X, list_in, L),
	fact(X, list_index, I),
	fact(L, length, N)
	==> 
	add_constraints([
		I #>= 1,
		I #=< N
	]).

% if list has an element type, then every element of that list has that type
rule,
	fact(L, a, list),
	fact(L, element_type, T),
	fact(Cell, list_in, L),
	fact(Cell, value, V)
	==>
	add_constraints([
		fact(V, a, T)
	]).

% if X is the previous item before Y, then Y is the next item after X, and vice versa.
% the next and previous items of an element are in the same list as that element 
rule, 
	fact(L, a, list),
	fact(Cell, list_in, L),
	fact(Cell, prev, Prev)
	==>
	add_constraints([
		fact(Prev, next, Cell),
		fact(Prev, list_in, L)
	]).
rule,
	fact(L, a, list),
	fact(Cell, list_in, L),
	fact(Cell, next, Next)
	==>
	add_constraints([
		fact(Next, prev, Cell),
		fact(Next, list_in, L)
	]).

% the next item after the item at list index I has list index I + 1
rule,
	fact(L, a, list),
	fact(Cell, list_in, L),
	fact(Cell, list_index, I),
	fact(Cell, next, Next), fact(Next, list_index, J)
	==>
	add_constraints([
		J #= I + 1
	]).

% OBJECTS/RELATIONS THEORY
/*
Required field:
 "required" here doesn't mean the user must explicitly supply the field, it just means that the field will always be created if it hasn't been supplied,
 i.e. it's an existence assertion, the field should probably be "exists" rather than "required"
*/
/*
rule,
fact(Object, a, Type) 
==> assert_relation_constraints(Type, Object).
*/

/* Unique field: */
rule,
	fact(Object, a, Type),
	fact(Type, a, relation),
	fact(Type, field, Field),
	fact(Field, key, Key),
	fact(Field, unique, true),
	fact(Object, Key, X) 
	\ 
	fact(Object, Key, Y)
	<=>
	debug(chr_object, "CHR: unique field rule: object=~w, type=~w, field=~w~n", [Object, Type, Key]),
	(	X = Y 
	-> 	true 
	; 	format(
			user_error,
			"Error: field ~w.~w must be unique but two distinct instances were found: `~w ~w ~w` and `~w ~w ~w`~n",
			[Type, Key, Object, Key, X, Object, Key, Y]
		),
		fail
	).

/* Typed field:	*/

rule,
	fact(Object, a, Type),
	fact(Type, a, relation),
	fact(Type, field, Field),
	fact(Field, key, Key),
	fact(Field, type, Field_Type),
	fact(Object, Key, Value)
	==>
	debug(chr_object, "CHR: typed field rule: object=~w, type=~w, field=~w, field_type=~w, value=~w~n", [Object, Type, Key, Field_Type, Value]),
		(
			Field_Type = list(Element_Type)
		->	fact(Value, a, list),
			fact(Value, element_type, Element_Type)
		;	fact(Value, a, Field_Type)
		).

/*
This is a catch-all for fact deduplication.
*/
rule, fact(S, P, O) \ fact(S, P, O) <=> true.



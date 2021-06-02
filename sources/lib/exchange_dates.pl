% discussion: https://github.com/lodgeit-labs/accounts-assessor/issues/47



 'dates for historical reports'(dates(Start_date,End_date,Exchange_date)) :-
 	Start_date = date(1,1,1),
 	!rp(l:start_date, Current_start_date),
	add_days(Current_start_date, -1, End_date),
	Exchange_date = Current_start_date.




'dates for posting Historical_Earnings'(Report_start_date, Dates) :-
	add_days(Report_start_date, -1, Before_start),
	doc_new_(l:dates, Dates),
	doc_add(Dates, [
		l:start_date, date(1,1,1),
		l:end_date, Before_start,
		l:exchange_date, Report_start_date,
		l:tx_date, Before_start]).

'dates for posting Current_Earnings'(Report_start_date, Report_end_date, Dates) :-

	doc_new_(l:dates, Dates),
	doc_add(Dates, [
		l:start_date, Report_start_date,
		l:end_date, Report_end_date,
		l:exchange_date, Report_end_date,
		l:tx_date, Report_end_date]).



/* - */

 make_without_currency_movement_against_since(Report_Currency, Since, [coord(Unit, D)], [coord(Unit2, D)]) :-
	Unit2 = without_currency_movement_against_since(
		Unit,
		Unit,
		Report_Currency,
		Since
	).

 vector_without_movement_after([coord(Unit1,D)], Start_Date, [coord(Unit2,D)]) :-
	Unit2 = without_movement_after(Unit1, Start_Date).




%"the historical half of the tracking transaction changes in value all the way to and including the day before report start"




 difference_transactions(
	Date,
	Vector_Exchanged_To_Report_Currency,
	Vector,
	(St,Currency_Movement_Account,Description,Transaction1,Transaction2,Transaction3)
) :-
	result_property(l:start_date, Start_Date),

	(
		Date @< Start_Date
	->
		(
			/* the historical earnings difference transaction tracks asset value change against converted/frozen earnings value, up to and including day before report start date  */
			add_days(Start_Date, -1, Before_start),
			vector_without_movement_after(Vector, Before_start, Vector_Frozen_Since_Before_start),
			make_difference_transaction(
				St,
				Currency_Movement_Account,
				Date,
				[Description, ' - historical part'],

				Vector_Frozen_Since_Before_start,
				Vector_Exchanged_To_Report_Currency,

				Transaction1),
			/* the current earnings difference transaction tracks asset value change against opening value */

			make_difference_transaction(
				St,
				Currency_Movement_Account,
				Start_Date,
				[Description, ' - current part'],

				Vector,
				Vector_Frozen_Since_Before_start,

				Transaction2)
		)
	;
		make_difference_transaction(
			St,
			Currency_Movement_Account,
			Date,
			[Description, ' - only current period'],

			Vector,
			Vector_Exchanged_To_Report_Currency,

			Transaction3
		)
	)
	.

/*
todo: trading difference transactions
*/



 clip_investment(Static_Data, I1, I2) :-
	Start_Date = Static_Data.start_date,
	Exchange_Rates = Static_Data.exchange_rates,
	Report_Currency = Static_Data.report_currency,
	add_days(Start_Date, -1, Before_Start),
	[Report_Currency_Unit] = Report_Currency,

	I1 = (Tag, Info1, Outstanding_Count, Sales),
	I2 = ir_item(Tag, Info2, Outstanding_Count, Sales, Clipped),

	Info1 = info(Investment_Currency, Unit, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
	Info2 = info2(Investment_Currency, Unit, Opening_Unit_Cost_Converted, Opening_Unit_Cost_Foreign, Opening_Date, Original_Purchase_Info),

	Original_Purchase_Info = original_purchase_info(Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),

	(
		Purchase_Date @>= Before_Start
	->
		(
			Opening_Unit_Cost_Foreign = Purchase_Unit_Cost_Foreign,
			Opening_Unit_Cost_Converted = Purchase_Unit_Cost_Converted,
			Opening_Date = Purchase_Date,
			Clipped = unclipped
		)
	;
		(
		/*
			clip start date, adjust purchase price.
			the simplest case is when the price in purchase currency at opening start date is specified by user, and this is what we rely on.
		*/
			Opening_Date = Before_Start,

			(	at_cost
			->	Unit2 = with_cost_per_unit(Unit, Purchase_Unit_Cost_Foreign)
			;	Unit2 = Unit),

			exchange_rate_throw(Exchange_Rates, Opening_Date, Unit2, Investment_Currency, Opening_Exchange_Rate_Foreign),
			Opening_Unit_Cost_Foreign = value(Investment_Currency, Opening_Exchange_Rate_Foreign),

			exchange_rate_throw(Exchange_Rates, Opening_Date, Unit2, Report_Currency_Unit, Opening_Exchange_Rate_Converted),
			Opening_Unit_Cost_Converted = value(Report_Currency_Unit, Opening_Exchange_Rate_Converted),

			Clipped = clipped
		)
	).


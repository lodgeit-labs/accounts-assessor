% historical_reports


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
		l:exchange_date, Start_date,
		l:tx_date, Start_date]).

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
			vector_without_movement_after(Vector, Start_Date, Vector_Frozen_At_Opening_Date),
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

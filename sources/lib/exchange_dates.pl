% historical_reports


 'dates for historical reports'(dates(Start_date,End_date,Exchange_date)) :-
 	Start_date = date(1,1,1),
 	!rp(l:start_date, Current_start_date),
	add_days(Current_start_date, -1, End_date),
	Exchange_date = Current_start_date.




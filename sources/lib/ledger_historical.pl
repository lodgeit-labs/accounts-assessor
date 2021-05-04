


 historical_reports(Vanilla_state, Balance_Sheet_Historical, ProfitAndLoss_Historical) :-
 	historical_dates(Historical_dates),
	Historical_dates = dates(Historical_start_date,Historical_end_date,_),
	!'with current and historical earnings equity balances'(
		Vanilla_state,
		Historical_start_date,
		Historical_end_date,
		State_historical
	),
	static_data_from_state(State_historical, Sd),
 	static_data_with_dates(Sd, Historical_dates, Sd2),
	!cf(balance_sheet_at(Sd2, Balance_Sheet_Historical)),
	!cf(profitandloss_between(Sd2, ProfitAndLoss_Historical)).



 static_data_historical(Static_Data, Static_Data_Historical) :-
	add_days(Static_Data.start_date, -1, Before_Start),
	Static_Data_Historical = Static_Data.put(
		start_date, date(1,1,1)).put(
		end_date, Before_Start).put(
		exchange_date, Static_Data.start_date).

 historical_dates(dates(Start_date,End_date,Exchange_date)) :-
 	!rp(l:start_date, Current_start_date),
 	%!rp(l:end_date, Current_end_date),
 	Start_date = date(1,1,1),
	add_days(Current_start_date, -1, End_date),
	Exchange_date = Current_start_date.

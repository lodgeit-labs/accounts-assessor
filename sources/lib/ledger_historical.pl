


 historical_reports(Vanilla_state, Balance_Sheet_Historical, ProfitAndLoss_Historical) :-
 	'dates for historical reports'(Historical_dates),
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


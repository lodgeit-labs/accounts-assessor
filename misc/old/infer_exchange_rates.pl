/*this functionality is disabled for now, maybe delete*/
infer_exchange_rates(_, _, _, _, _, _, Exchange_Rates, Exchange_Rates) :- 
	!.

%infer_exchange_rates(Transactions, S_Transactions, Start_Date, End_Date, Accounts, Report_Currency, Exchange_Rates, Exchange_Rates_With_Inferred_Values) :-
	%/* a dry run of bs_and_pl_entries to find out units used */
	%trial_balance_between(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, Trial_Balance),
	%balance_sheet_at(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, Balance_Sheet),

	%profitandloss_between(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, ProfitAndLoss),
	%bs_and_pl_entries(Accounts, Report_Currency, none, Balance_Sheet, ProfitAndLoss, Used_Units, _, _),
	%pretty_term_string(Balance_Sheet, Message4),
	%pretty_term_string(Trial_Balance, Message4b),
	%pretty_term_string(ProfitAndLoss, Message4c),
	%atomic_list_concat([
		%'\n<!--',
		%'BalanceSheet:\n', Message4,'\n\n',
		%'ProfitAndLoss:\n', Message4c,'\n\n',
		%'Trial_Balance:\n', Message4b,'\n\n',
		%'-->\n\n'], 
	%Debug_Message2),
	%writeln(Debug_Message2),
	%assertion(ground((Balance_Sheet, ProfitAndLoss, Trial_Balance))),
	%pretty_term_string(Used_Units, Used_Units_Str),
	%writeln('<!-- units used in balance sheet: \n'),
	%writeln(Used_Units_Str),
	%writeln('\n-->\n'),
	%fill_in_missing_units(S_Transactions, End_Date, Report_Currency, Used_Units, Exchange_Rates, Inferred_Rates),
	%pretty_term_string(Inferred_Rates, Inferred_Rates_Str),
	%writeln('<!-- Inferred_Rates: \n'),
	%writeln(Inferred_Rates_Str),
	%writeln('\n-->\n'),
	%append(Exchange_Rates, Inferred_Rates, Exchange_Rates_With_Inferred_Values).

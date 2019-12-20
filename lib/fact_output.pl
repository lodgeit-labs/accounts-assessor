:- module(_, []).

:- use_module('accounts').
:- use_module(library(xbrl/utils)).

:- use_module(library(rdet)).
:- use_module(library(xbrl/structured_xml)).

:- rdet(format_balance/11).
:- rdet(format_balances/11).
:- rdet(pesseract_style_table_rows/4).
:- rdet(format_report_entries/10).


format_report_entries(_, _, _, _, _, _, [], Used_Units_In, Used_Units_Out, []) :-
	(Used_Units_In = Used_Units_Out, Lines_In = Lines_Out -> true ; throw('internal error 2')).

format_report_entries(Format, Max_Detail_Level, Accounts, Indent_Level, Report_Currency, Context, Entries, Used_Units_In, Used_Units_Out, [Xml0, Xml1, Xml2]) :-
	[entry(Name, Balances, Children, Transactions_Count)|Entries_Tail] = Entries,
	(
		/* does the account have a detail level and is it greater than Max_Detail_Level? */
		(accounts:account_detail_level(Accounts, Name, Detail_Level), Detail_Level > Max_Detail_Level)
	->
		/* nothing to do */
		(
			Used_Units_In = Used_Units_Out, 
			Lines_In = Lines_Out
		)
	;
		(
			accounts:account_normal_side(Accounts, Name, Normal_Side),
			
			(
				/* should we display an account with zero transactions? */
				(Balances = [],(Indent_Level = 0; Transactions_Count \= 0))
			->
				/* force-display it */
				format_balance(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, [],
					Used_Units_In, UsedUnitsIntermediate, Xml0)
			;
				/* if not, let the logic omit it entirely */
				format_balances(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, Balances, 
					Used_Units_In, UsedUnitsIntermediate, Xml0)
			),

			Level_New is Indent_Level + 1,
			/*display child entries*/
			format_report_entries(Format, Max_Detail_Level, Accounts, Level_New, Report_Currency, Context, Children, UsedUnitsIntermediate, UsedUnitsIntermediate2, Xml1),
			/*recurse on Entries_Tail*/
			format_report_entries(Format, Max_Detail_Level, Accounts, Indent_Level, Report_Currency, Context, Entries_Tail, UsedUnitsIntermediate2, Used_Units_Out, Xml2)
		)
	),
	!.
	
pesseract_style_table_rows(_, _, [], []).

pesseract_style_table_rows(Accounts, Report_Currency, Entries, [Lines|Lines_Tail]) :-
	[entry(Name, Balances, Children, _)|Entries_Tail] = Entries,
	/*render child entries*/
	pesseract_style_table_rows(Accounts, Report_Currency, Children, Children_Lines),
	/*render balance*/
	maybe_balance_lines(Accounts, Name, Report_Currency, Balances, Balance_Lines),
	(
		Children_Lines = []
	->
		
		(
			Lines = [tr([td(Name), td(Balance_Lines)])]
			
		)
	;
		(
			flatten([tr([td([b(Name)])]), Children_Lines, [tr([td([align="right"],[Name]), td(Balance_Lines)])]], Lines)

		)		
	),
	/*recurse on Entries_Tail*/
	pesseract_style_table_rows(Accounts, Report_Currency, Entries_Tail, Lines_Tail).
			
maybe_balance_lines(Accounts, Name, Report_Currency, Balances, Balance_Lines) :-
	accounts:account_normal_side(Accounts, Name, Normal_Side),
	(
		Balances = []
	->
		/* force-display it */
		format_balance(html, 0, Report_Currency, '', Name, Normal_Side, Balances,
			[], _, Balance_Lines)
	;
		/* if not, let the logic omit it entirely */
		format_balances(html, 0, Report_Currency, '', Name, Normal_Side, Balances, 
			[], _, Balance_Lines)
	).
			
format_balances(_, _, _, _, _, _, [], Used_Units, Used_Units, []]).

format_balances(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, [Balance|Balances], Used_Units_In, Used_Units_Out, [XmlH|XmlT]) :-
	format_balance(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, [Balance], Used_Units_In, UsedUnitsIntermediate, Lines_In, XmlH),
	format_balances(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, Balances, UsedUnitsIntermediate, Used_Units_Out, XmlT).

format_balance(Format, Indent_Level, Report_Currency_List, Context, Name, Normal_Side, [], Used_Units_In, Used_Units_Out, Xml) :-
	(	[Report_Currency] = Report_Currency_List
	->	true
	;	Report_Currency = 'AUD' % just for displaying zero balance),
	format_balance(Format, Indent_Level, _, Context, Name, Normal_Side, [coord(Report_Currency, 0)], Used_Units_In, Used_Units_Out, Xml).
   
format_balance(Format, Indent_Level, Report_Currency_List, Context, Name, Normal_Side, Coord, Units_In, Units_Out, Line) :-
	[coord(Unit, Debit)] = Coord,
	sane_unit_id(Units_In, Units_Out, Unit, Unit_Xml_Id),
	(	Normal_Side = credit
	->	Balance0 is -Debit
	;	Balance0 is Debit),
	utils:round(Balance0, 2, Balance1),
	(	Balance1 =:= 0
	->	Balance = 0 % get rid of negative zero
	;	Balance = Balance0),
	%utils:get_indentation(Indent_Level, Indentation),
	(	Format = xbrl
	->	(
			format(string(Amount), '~2:f', [Balance]),
			Line = element(basic, [
				contextRef=Context,
				unitRef=sane_id(Unit_Ref),
				decimals="INF"],
				[Balance])
		)
	;
		(
			utils:round_term(Unit, Rounded_Unit),
			(	Report_Currency_List = [Unit]
			->	Printed_Unit = ''
			;	Printed_Unit = Rounded_Unit),
			format(string(Line), '~2:f~w\n', [Balance, Printed_Unit])
		)
	).


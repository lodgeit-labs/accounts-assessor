
%:- rdet(format_balance/11).
%:- rdet(format_balances/11).
%:- rdet(pesseract_style_table_rows/4).
%:- rdet(format_report_entries/8).


format_report_entries(_, _, _, _, _, _, [], []).

format_report_entries(Format, Max_Detail_Level, Accounts, Indent_Level, Report_Currency, Context, Entries, [Xml0, Xml1, Xml2]) :-
	[entry(Name, Balances, Children, Transactions_Count, _)|Entries_Tail] = Entries,
	(	/* does the account have a detail level and is it greater than Max_Detail_Level? */
		(account_detail_level(Accounts, Name, Detail_Level), Detail_Level > Max_Detail_Level)
	->
		true /* nothing to do */
	;
		(
			account_normal_side(Accounts, Name, Normal_Side),
			
			(
				/* should we display an account with zero transactions? */
				(Balances = [],(Indent_Level = 0; Transactions_Count \= 0))
			->
				/* force-display it */
				format_balance(Format, Report_Currency, Context, Name, Normal_Side, [], Xml0)
			;
				/* if not, let the logic omit it entirely */
				format_balances(Format, Report_Currency, Context, Name, Normal_Side, Balances, Xml0)
			),

			Level_New is Indent_Level + 1,
			/*display child entries*/
			format_report_entries(Format, Max_Detail_Level, Accounts, Level_New, Report_Currency, Context, Children, Xml1),
			/*recurse on Entries_Tail*/
			format_report_entries(Format, Max_Detail_Level, Accounts, Indent_Level, Report_Currency, Context, Entries_Tail, Xml2)
		)
	),
	!.

/*
coord(
	Unit						% atom:Unit
	Debit						% Numeric
).
*/

/*
entry(
	Name						% atom:Entry Name
	Balances					% List ...
	Children					% List entry
	?							% 
).
*/





/*
pesseract_style_table_rows(
	Accounts,					% List record:account
	Report_Currency,			% List atom:Report Currency
	Entries,					% List entry
	[Lines|Lines_Tail]			% List (List line)
) 
*/	

pesseract_style_table_rows(_, _, [], []).
pesseract_style_table_rows(
	Accounts,
	Report_Currency,
	Entries,
	[Lines|Lines_Tail]
) :-
	[entry(Name, Balances, Children, _, Misc)|Entries_Tail] = Entries,
	/*render child entries*/
	pesseract_style_table_rows(Accounts, Report_Currency, Children, Children_Lines),
	/*render balance*/
	maybe_balance_lines(Accounts, Name, Report_Currency, Balances, Balance_Lines),
	(
		Children_Lines = []
	->
		(
			findall(td(M),member(M, Misc),Misc_Tds),
			Lines = [tr([td(Name), td(Balance_Lines)|Misc_Tds])]
			
		)
	;
		(
			flatten([tr([td([b(Name)])]), Children_Lines, [tr([td([align="right"],[Name]), td(Balance_Lines)])]], Lines)

		)		
	),
	/*recurse on Entries_Tail*/
	pesseract_style_table_rows(Accounts, Report_Currency, Entries_Tail, Lines_Tail).




/*
maybe_balance_lines(
	Accounts,			% List record:account 
	Name,				% atom:Entry Name
	Report_Currency,	% List atom:Report Currency
	Balances,			% List ...
	Balance_Lines		% List ...
) 
*/
			
maybe_balance_lines(
	Accounts,
	Name,
	Report_Currency,
	Balances,
	Balance_Lines
) :-
	account_normal_side(Accounts, Name, Normal_Side),
	(
		Balances = []
	->
		/* force-display it */
		format_balance(html, Report_Currency, '', Name, Normal_Side, Balances, Balance_Lines)
	;
		/* if not, let the logic omit it entirely */
		format_balances(html, Report_Currency, '', Name, Normal_Side, Balances, Balance_Lines)
	).



			
/*
format_balances(
	Format,				% atom:{html,xbrl}
	Report_Currency,	% List atom:Report Currency
	Context,			% 
	Name,				% atom:Entry Name
	Normal_Side,		% atom:{credit,debit}
	Balances,			% List ...
	Balance_Lines		% List ...
).
*/
format_balances(_, _, _, _, _, [], []).

format_balances(Format, Report_Currency, Context, Name, Normal_Side, [Balance|Balances], [XmlH|XmlT]) :-
	format_balance(Format,  Report_Currency, Context, Name, Normal_Side, [Balance], XmlH),
	format_balances(Format, Report_Currency, Context, Name, Normal_Side, Balances, XmlT).

format_balances(Format, Report_Currency, Context, Name, Normal_Side, Balances_Uri, Xml) :-
	atom(Balances_Uri),
	doc(Balances_Uri, rdf:value, Balances),
	format_balances(Format, Report_Currency, Context, Name, Normal_Side, Balances, Text),
	Xml = span(
		$>append(
			Text,
			[a(href=Balances_Uri, [small('⍰')])])).



/*
format_balance(
	Format,					% atom:{html,xbrl}
	Report_Currency_List,	% List atom:Report Currency
	Context,				%
	Name,					% atom:Entry Name
	Normal_Side,			% atom:{credit,debit}
	Coord,					% Vector coord {0,1}
	Xml						% ...
).
*/

% should either be cutting here or changing Coord to [coord(Unit, Debit)]
format_balance(Format, Report_Currency_List, Context, Name, Normal_Side, [], Xml) :-
	% just for displaying zero balance when the balance vector is []), % fixme, change to ''
	(	[Report_Currency] = Report_Currency_List
	->	true
	;	Report_Currency = 'AUD'),
	format_balance(Format, _, Context, Name, Normal_Side, [coord(Report_Currency, 0)], Xml).

  
format_balance(Format, Report_Currency_List, Context, Name, Normal_Side, Coord, Line) :-
	[coord(Unit, Debit)] = Coord,

	(	Normal_Side = credit
	->	Balance0 is -Debit
	;	Balance0 is Debit),

	round(Balance0, 2, Balance1),

	(	Balance1 =:= 0
	->	Balance = 0 % get rid of negative zero
	;	Balance = Balance0),

	(	Format = xbrl
	->
		format(string(Amount), '~2:f', [Balance]),

		atomic_list_concat(['basic:', Name], Fact_Name), % fixme
		sane_unit_id(Unit, Sane_Unit_Id),
		Line = element(Fact_Name,
		[
			contextRef=Context,
			unitRef=Sane_Unit_Id,
			decimals="INF"],
			[Amount]),
		request_assert_property(l:has_used_unit, Unit, xml)
	;
		(	Report_Currency_List = [Unit]
		->	Printed_Unit = ''
		;	round_term(Unit, Printed_Unit)),
		format(string(Line), '~2:f~w\n', [Balance, Printed_Unit])
	).

sane_unit_id(Unit, Id) :-
	sane_id(Unit, 'U-', Id).

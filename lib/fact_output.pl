format_report_entries(_, _, _, _, _, _, [], []).

format_report_entries(Format, Max_Detail_Level, Indent_Level, Report_Currency, Context, Entries, [Xml0, Xml1, Xml2]) :-
	[entry(Name, Balances, Children, Transactions_Count, _)|Entries_Tail] = Entries,
	(	/* does the account have a detail level and is it greater than Max_Detail_Level? */
		(account_detail_level(Name, Detail_Level), Detail_Level > Max_Detail_Level)
	->
		true /* nothing to do */
	;
		(
			account_normal_side(Name, Normal_Side),
			
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
			format_report_entries(Format, Max_Detail_Level, Level_New, Report_Currency, Context, Children, Xml1),
			/*recurse on Entries_Tail*/
			format_report_entries(Format, Max_Detail_Level, Indent_Level, Report_Currency, Context, Entries_Tail, Xml2)
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
	Report_Currency,
	Entries,
	[Lines|Lines_Tail]
) :-
	[Entry|Entries_Tail] = Entries,
	report_entry_name(Entry, Name),
	report_entry_total_vec(Entry, Balances),
	report_entry_children(Entry, Children),

	/*render child entries*/
	pesseract_style_table_rows(Report_Currency, Children, Children_Rows),
	/*render balance*/
	maybe_balance_lines(Name, Report_Currency, Balances, Balance_Lines),
	(	Children_Rows = []
	->	entry_row_childless(Name, Balance_Lines, Entry, Lines)
	;	entry_row_childful(Name, Entry, Children_Rows, Balance_Lines, Lines)),
	/*recurse on Entries_Tail*/
	pesseract_style_table_rows(Report_Currency, Entries_Tail, Lines_Tail).

entry_row_childless(Name, Balance_Lines, Entry, Lines) :-
	entry_row(cols{0:Name,1:Balance_Lines}, Entry, report_entries:single, Lines).

entry_row_childful(Name, Entry, Children_Rows, Balance_Lines, Lines) :-
	Lines =
	[
		$>entry_row(cols{0:b([Name])}, Entry, report_entries:header),
		Children_Rows,
		$>entry_row(cols{0:td([align="right"],[Name]),1:Balance_Lines}, Entry, report_entries:footer)
	].

merge_dicts(D1, D2, D3) :-
	dict_pairs(D1, Tag, P1),
	dict_pairs(D2, Tag, P2),
	append(P1, P2, P3),
	dict_pairs(D3, Tag, P3).

miscs_dict(Entry, Type, Dict) :-
	findall(
		Col_Pos-Item,
		(
			between(1,5,C),
			Col_Pos is C + 1,
			entry_misc_item_for_column(Entry, Type, C, Item)
		),
		Pairs),
	dict_pairs(Dict, cols, Pairs).

entry_misc_item_for_column(Entry, Type, Column, Item) :-
	doc(Entry, report_entries:misc, D1),
	doc(D1, report_entries:column, Column),
	doc(D1, report_entries:misc_type, $>rdf_global_id(Type)),
	doc(D1, report_entries:value, Item).

entry_row(Cols0, Entry, Type, Row) :-
	%(atom(Entry) -> gtrace ; true),
	miscs_dict(Entry, Type, Miscs_Dict),
	merge_dicts(Cols0, Miscs_Dict, Cols),
	cols_dict_to_row(Cols, Row).

cols_dict_to_row(Cols, tr(Tds)) :-
	dict_pairs(Cols, _, Pairs),
	findall(I,cols_dict_to_row_helper(Pairs, I), Tds).

cols_dict_to_row_helper(Pairs, I) :-
	between(0,6,C),
	cols_dict_to_row_helper2(C, Pairs, I).

cols_dict_to_row_helper2(C, Pairs, I) :-
	member(C-Item, Pairs),
	cols_dict_to_row_helper3(Item, I).

cols_dict_to_row_helper2(C, Pairs, td([])) :-
	\+member(C-_, Pairs),
	there_is_item_after(C, Pairs).

cols_dict_to_row_helper3(Item, I) :-
	(	Item =.. [td|_]
	->	I = Item
	;	(
			I = td(Item2),
			flatten([Item], Item2)
		)).



there_is_item_after(C, Pairs) :-
	findall(X,
		(
			member(C2-X, Pairs),
			C2 > C
		),
		Items),
	Items \= [].

/*
maybe_balance_lines(
	Accounts,			% List record:account 
	Name,				% atom:Entry Name
	Report_Currency,	% List atom:Report Currency
	Balances,			% List ...
	Balance_Lines		% List ...
) 
*/
			/*not much of a maybe anymore?*/
maybe_balance_lines(
	Name,
	Report_Currency,
	Balances,
	Balance_Lines
) :-
	account_normal_side(Name, Normal_Side),
	/* force-display empty balance */
	(	Balances = []
	->	format_balance(html, Report_Currency, '', Name, Normal_Side, [], Balance_Lines)
	;	format_balances(html, Report_Currency, '', Name, Normal_Side, Balances, Balance_Lines)).



			
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
			[$>link(Balances_Uri)])).



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

	(	Normal_Side = kb:credit
	->	Balance0 is -Debit
	;	(
			assertion(Normal_Side = kb:debit),
			Balance0 is Debit
	)),

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

		
table_to_html(
	Table, 
	[
		Table.title, ':',
		br([]),
		HTML_Table
	]
) :-
	format_table(Table, Formatted_Table),
	table_contents_to_html(Formatted_Table, HTML_Table).

table_contents_to_html(
	table{title:_, columns: Columns, rows: Rows},
	table([border="1"],[HTML_Header | HTML_Rows])
) :-
	% make HTML Header
	maplist(
		[Column,Header_Cell]>>(Header_Cell is td(Column.title)), 
		Columns, 
		Header_Cells
	),
	/*
	findall(
		td(Header_Value),
		(
			member(Column, Columns),
			Header_Value = Column.title
		),
		Header_Cells
	),
	*/

	HTML_Header = tr(Header_Cells),

	% make HTML Rows 
	% maplist ?
	findall(
		tr(HTML_Row),
		(
			member(Row,Rows),
			findall(
				td(Cell),
				(
					member(Column, Columns),
					Cell = Row.(Column.id)
				),
				HTML_Row
			)
		),
		HTML_Rows
	).

format_table(
	table{title:Title, columns:Columns, rows:Rows}, 
	table{title:Title, columns:Columns, rows:Formatted_Rows}
) :-
	maplist(format_row(Columns),Rows,Formatted_Rows).

format_row(Columns, Row, Formatted_Row) :-
	findall(
		Column_Id:Formatted_Cell,
		(
			member(Column, Columns),
			Column_Id = Column.id
			format_cell(Row.Column_Id, Column.options, Formatted_Cell)
		),
		Formatted_Row_KVs
	),
	dict_create(Formatted_Row,row,Formatted_Row_KVs).



flatten_groups(Groups, Columns) :-
	findall(
		Group_Columns,
		(
			member(Group, Groups),
			group_columns(Group, Group_Columns)
		),
		Columns_Nested
	),
	flatten(Columns_Nested, Columns).

group_columns(
	group{id:Group_ID, title:Group_Title, members:Group_Members},
	Group_Columns
) :-
	findall(
		column{
			id:Group_ID/Member_ID,
			title:Column_Title,
			options:Options
		},
		(
			member(column{id:Member_ID, title:Member_Title, options:Options}, Group_Members),
			atomics_to_string([Group_Title, Member_Title], " ", Column_Title),
		),
		Group_Columns
	).

format_cell(date(Date), Options, Output) :-
	!,
	format_date(Date, Output).

format_cell(value(Unit, Value), Options, Output) :-
	!,
	(
		Precision = Options.get(precision)
	->
		true
	;
		Precision = 2
	),
	format_money2(_, Precision, value(Unit, Value), Output).

format_cell(exchange_rate(Date, Src, Dst, Rate), Options, Output) :-
	!,
	format_conversion(_, exchange_rate(Date, Src, Dst, Rate), Output).

format_cell(Other, Options, Other).


format_money_precise(Optional_Implicit_Unit, In, Out) :-
	format_money2(Optional_Implicit_Unit, 6, In, Out).
	
format_money(Optional_Implicit_Unit, In, Out) :-
	format_money2(Optional_Implicit_Unit, 2, In, Out).

format_money2(_Optional_Implicit_Unit, Precision, In, Out) :-
	(
		In = ''
	->
		Out = ''
	;
		(
			In = value(Unit1,X)
		->
			true
		;
			(
				X = In,
				Unit1 = '?'
			)
		),
		(
			false%member(Unit1, Optional_Implicit_Unit)
		->
			Unit2 = ''
		;
			Unit2 = Unit1
		),
		atomic_list_concat(['~',Precision,':f~w'], Format_String),
		format(string(Out), Format_String, [X, Unit2])
	).







format_conversion(_Report_Currency, '', '').
	
format_conversion(_Report_Currency, Conversion, String) :-
	Conversion = exchange_rate(_, Src, Dst, Rate),
	Inverse is 1 / Rate,
	format(string(String), '1~w=~6:f~w', [Dst, Inverse, Src]). 
	%pretty_term_string(Conversion, String).

optional_converted_value(V1, C, V2) :-
	(
		C = ''
	->
		V2 = ''
	;
		value_convert(V1, C, V2)
	).





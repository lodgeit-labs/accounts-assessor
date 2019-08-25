/*
% i would just call this table_html because the particular html representation
				% may change but the pred is still just converting a table to html in any case <- this seems to be the point
^ lol at the indenting
idk, table_div seems more to the point
well, i dont care, whatever you deem right
but table_html should be just table html, not table title + stuff + html
  lets keep going
  well the terminology is somewhat inadequate here because there's html tables
  but then there's our internal notion of a table
  which should maybe be called a "report" instead, idk
  nvm, just report is right
  just as long as we can be clear that the semantics of this pred is supposed to be like
  yea, i deally we would have a clearer mental model for the different pieces of this
  but i guess that's a work in progress
  i'd agree
  lets keep going
*/
 
/*
  <internal representation of ... whatever> to <html something>
  Table - internal representation of whatever
  second argument - something html
*/ 
table_html(
	Table, 
	[div([span([Table.title, ':']), HTML_Table])]
) :-
	format_table(Table, Formatted_Table),
	table_contents_to_html(Formatted_Table, HTML_Table)
	.
/*
  this one converts the actual tabular data in the report to an
  actual html table
  first argument - internal representation of tabular data, formatted into strings, flat?
with id's like a or a/b? that's how it's currently set up yea, which is simplest if we're
  only anticipating to produce a flat table as output
  if we end up wanting something like multi-level headers to indicate the grouping then
  we might want to be passing it the structured data here
  ok one problem with the code now is that dict keys have to be simple atoms
  i'd go for the structuredness
  ic
  
  second argument - html_write table term/input
  no its just a plain term
  phrase/2 translates the plain term into ... other stuff
  here i'm just looking for some term that differentiates these compound
  atoms representing html from actual <table>...</table> html
  html_write terms
  html_write input
  
*/
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
				 path_get_dict(Column.id, Row, Cell) %should do
				%	Cell = Row.(Column.id)
				),
				HTML_Row
			)
		),
		HTML_Rows
	).

/*
  should we just maplist in table_p directly?
  my thought here was that we might have different output formats besides HTML
  but the formatting itself (in the abstract) stays the same
  idk, this is just like...when we have other formats, we can abstract it
  other formats like xbrl maybe?
  idk what other formats you anticipate, i would have to tahink a while to imagine how we'd use it with xbrl
  w/e
  well, what i'm really thinking here now is that the table_html shouldn't be concerned w/ this
  type of formatting and should be receiving pre-formatted data as input
  sounds good but i'd bet money that each hypothetical output format will need to do different formatting
*/
format_table(
	table{title:Title, columns:Columns, rows:Rows}, 
	table{title:Title, columns:Columns, rows:Formatted_Rows}
) :-
	maplist(format_row(Columns),Rows,Formatted_Rows).

/*
 so i guess this one needs to recurse on groups basically
 or maybe rather when it encounters a group needs to call something like
 format_group which does that
*/
format_row(Columns, Row, Formatted_Row) :-
	findall(
		Column_ID:Formatted_Cell,
		(
		 member(Column, Columns),
		% maybe split this part off into a predicate that can do this if/else as
		 % pattern-matching in the head
		 (
		  % if it's a group of columns, recurse on the members
		  Column = group{id:Column_ID, title:_, members:Group_Members}
		 ->
		  format_row(Group_Members, Row.Column_ID, Formatted_Cell)
		 ;
		  (
		   % else if it's a single column, format the individual cell
		   Column = column{id:Column_ID, title:_, options:Column_Options}
		  ->
		   format_cell(Row.Column_ID, Column_Options, Formatted_Cell)
		  )
		 )		  
		),
		Formatted_Row_KVs
	),
	dict_create(Formatted_Row,row,Formatted_Row_KVs).

% format_group(group{id:Group_ID, title:_, members:Group_Members}, Row, Group_ID:Formatted_Group) :-
	


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
			atomics_to_string([Group_Title, Member_Title], " ", Column_Title)
		),
		Group_Columns
	).

format_cell(date(Date), _, Output) :-
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

format_cell(exchange_rate(Date, Src, Dst, Rate), _, Output) :-
	!,
	format_conversion(_, exchange_rate(Date, Src, Dst, Rate), Output).

format_cell(Other, _, Other).


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


/* Rows - dict, possibly with subdicts */
/* Keys - list of id's that should be totalled */
/* Totals - possibly nested dict */
table_totals(Rows, Keys, Totals) :-
	table_totals2(Rows, Keys, _{}, Totals).

table_totals(Rows, [Key|Keys], In, Out) :-
	Out = In.put(Key, Total),
	column_by_key(Rows, Key, Vals),
	sum_cells(Vals, Total).

column_by_key(Rows, Key, Vals) :-
	findall(
		Val,
		(
		 member(Row, Rows),
		 path_get_dict(Key, Row, Val)
		),
		Vals
	       ).

sum_cells(Values, Sum) :-
	foldl(add_cells, Values, [], Sum).
	
add_cells(A, B, C) :-
	coord_merge(A, B, C).




		  


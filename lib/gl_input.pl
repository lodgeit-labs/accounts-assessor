 extract_gl_inputs(Txs) :-
 	(	doc($>request_data, ic_ui:gl, Gls)
 	->	(	maplist(!extract_gl_input, $>doc_list_items(Gls), Txs0),
			flatten(Txs0, Txs))
	;	Txs = []).

 extract_gl_input(Gl, Txs) :-
	!doc_value(Gl, ic:default_currency, Default_Currency0),
	!atom_string(Default_Currency, Default_Currency0),
	!doc_value(Gl, ic:items, List),
	!doc_list_items(List, Items),
	!doc_value(Gl, excel:has_sheet_name, Sheet_name),
	!extract_gl_tx(Sheet_name, Default_Currency, none, none, Items, Txs).

 extract_gl_tx(_, _, _,_,[],[]).

 extract_gl_tx(Sheet_name, Default_Currency, St0, Date0, [Item|Items], [Tx|Txs]) :-
	\+doc_value(Item, ic:date, _),
	(Date0 = none ->throw_string('GL_input: date missing');true),
	(St0 = none ->throw_string('GL_input: format error');true),
	!read_gl_line(Default_Currency, Date0, St0, Item, Tx),
	!extract_gl_tx(Sheet_name, Default_Currency, St0, Date0, Items, Txs).

extract_gl_tx(Sheet_name, Default_Currency, St0, Date0, [Item|Items], Txs) :-
	!doc_value(Item, ic:date, Date1),
	Date1 = "ignore",
	!extract_gl_tx(Sheet_name, Default_Currency, St0, Date0, Items, Txs).

extract_gl_tx(Sheet_name, Default_Currency, _, _, [Item|Items], [Tx|Txs]) :-
	!doc_value(Item, ic:date, Date1),
	Date1 \= "ignore",
	!doc_new_uri(gl_input_st, St1),
	!doc_add_value(St1, transactions:description, Sheet_name, transactions),
	!doc_add_value(St1, transactions:gl_input_sheet_item, Item, transactions),
	!read_gl_line(Default_Currency, Date1, St1, Item, Tx),
	!extract_gl_tx(Sheet_name, Default_Currency, St1, Date1, Items, Txs).


 read_gl_line(Default_Currency, Date, St, Item, Tx) :-
	!doc_value(Item, ic:account, Account_String),
	/* todo, support multiple description fields in transaction */
	(	doc_value(Item, ic:description, Description)
	->	true
	;	Description = 'GL_input'),
	(	doc_value(Item, ic:debit, Debit_String)
	->	vector_from_string(Default_Currency, kb:debit, Debit_String, Debit_Vector)
	;	Debit_Vector = []),
	(	doc_value(Item, ic:credit, Credit_String)
	->	vector_from_string(Default_Currency, kb:credit, Credit_String, Credit_Vector)
	;	Credit_Vector = []),
	append(Debit_Vector, Credit_Vector, Vector),
	!gl_entry_account_syntax_parameters(Item, Parameters),
	!resolve_account_syntax(Account_String, Parameters, Account),
	!make_transaction(St, Date, Description, Account, Vector, Tx).

 gl_entry_account_syntax_parameters(Item, Parameters) :-
	findall(
		Parameter,
		(
			between(1, 5, I),
			doc_value(Item, $>atomic_list_concat([$>rdf_global_id(ic:param),I]), Str),
			atom_string(Parameter, Str)
		),
		Parameters).

 resolve_account_syntax(String, Parameters, Account) :-
 	!string_codes(String, Codes),
 	!phrase(account_syntax(Specifier), Codes),
	(	Specifier = name(Name_str)
	->	(	atom_string(Name, Name_str),
			!account_by_ui(Name, Account))
	;	(
			!fill_slots(Specifier, Parameters, Role_list),
			!role_list_to_term(Role_list, Role),
			abrlt(Role, Account)
		)).

account_syntax(name(Name)) --> string_without("<!", Codes), {atom_codes(Name, Codes)}.
account_syntax(Role) --> `!`, account_syntax2(Role).
account_syntax2([H]) --> account_syntax2_part(H).
account_syntax2([H|T]) --> account_syntax2_part(H), `!`, account_syntax2(T).
account_syntax2_part(fixed(P)) --> string_without("<>!", Ps),{atom_string(P, Ps)}.
account_syntax2_part(slot(P)) --> `<`, string_without("<>!", Ps), `>`,{atom_string(P, Ps)}.




fill_slots([], [], []) :- !.

fill_slots([slot(_)|Slots], [Param|Params], [Param|RoleT]) :-
	!fill_slots(Slots, Params, RoleT),
	!.

fill_slots([fixed(Part)|Slots], Params, [Part|RoleT]) :-
	atom(Part),
	!fill_slots(Slots, Params, RoleT),
	!.

fill_slots([], [H|_], []) :-
	throw_string(['no slot for parameter: "', H, '"']).

fill_slots([H|_], [], []) :-
	throw_string(['no parameter for slot: "', H, '"']).


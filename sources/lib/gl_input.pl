 extract_gl_inputs(Txs) :-
 	(	doc($>request_data, ic_ui:gl, Gls)
 	->	(	maplist(!extract_gl_input, $>doc_list_items(Gls), Txs0),
			flatten(Txs0, Txs))
	;	Txs = []).

 extract_action_inputs(Txs) :-
 	(	doc($>request_data, ic_ui:action_input, Input)
 	->	(	maplist(!extract_action_input, $>doc_list_items(Input), Txs0),
			flatten(Txs0, Txs))
	;	Txs = []).

 extract_gl_input(Gl, Txs) :-
 	push_format('extract GL input from: ~w', [$>sheet_and_cell_string(Gl)]),
	!doc_value(Gl, ic:default_currency, Default_Currency0),
	!atom_string(Default_Currency, Default_Currency0),
	!doc_value(Gl, ic:items, List),
	!doc_list_items(List, Items),
	!doc_value(Gl, excel:has_sheet_name, Sheet_name),
	!extract_gl_tx(Sheet_name, Default_Currency, none, none, Items, Txs),
	!check_trial_balance(
		$>result_has_property(l:exchange_rates),
		$>result_has_property(l:report_currency),
		$>result_has_property(l:end_date),
		Sheet_name,
	Txs),
	pop_context.

 extract_action_input(Input, Txs) :-
 	push_context($>format(string(<$), 'extract action input from: ~w', [$>sheet_and_cell_string(Input)])),
	!doc_value(Input, ic:account, First_account),
	!doc_value(Input, ic:items, List),
	!doc_list_items(List, Items),
	!doc_value(Input, excel:has_sheet_name, Sheet_name),
	maplist(!'extract action_input item'(Sheet_name, First_account), Items, Txs0),
	flatten(Txs0, Txs),
	pop_context.

'extract action_input item'(Sheet_name, First_account, Item, St) :-
	push_context($>format(string(<$), 'extract item at ~w', [$>sheet_and_cell_string(Item)])),

	!result_has_property(l:report_currency, [Default_Currency]),

	(	doc_value(Item, ic:debit, Debit_String)
	->	!vector_from_string(Default_Currency, kb:debit, Debit_String, Debit_Vector)
	;	Debit_Vector = []),

	(	doc_value(Item, ic:credit, Credit_String)
	->	!vector_from_string(Default_Currency, kb:credit, Credit_String, Credit_Vector)
	;	Credit_Vector = []),

	!vec_add(Debit_Vector, Credit_Vector, Vector),

	Vector = [coord(_,Dr)],

	(	Dr >= 0
	->	Money_side = kb:debit
	;	Money_side = kb:credit),

	(	doc_value(Item, ic:units_count, Units_count)
	->	true
	;	Units_count = nil(nil)),

	(	doc_value(Item, ic:units_type, Units_type_str)
	->	atom_string(Units_type, Units_type_str)
	;	Units_type = nil(nil)),

	!extract_exchanged_value2(Money_side, Units_type, Units_count, Exchanged),

	(	doc_value(Item, ic:description2, Description2)
	->	true
	;	Description2 = Sheet_name),

	(	doc_value(Item, ic:description3, Description3)
	->	true
	;	Description3 = ''),

	doc_add_s_transaction(
		$>!read_date(Item, ic:date),
		$>atom_string(<$, $>rpv(Item, ic:action_verb)),
		Vector,
		account_name_ui_string(First_account),
		Exchanged,
		misc{desc2:Description2,desc3:Description3},
		St
	),

	pop_context.


 extract_gl_tx(_, _, _,_,[],[]).

 extract_gl_tx(Sheet_name, Default_Currency, St0, Date0, [Item|Items], [Tx|Txs]) :-
	\+doc_value(Item, ic:date, _),
	(Date0 = none ->throw_string([Sheet_name, ': date missing']);true),
	(St0 = none ->throw_string([Sheet_name, ': format error']);true),
	!read_gl_line(Sheet_name, Default_Currency, Date0, St0, Item, Tx),
	!extract_gl_tx(Sheet_name, Default_Currency, St0, Date0, Items, Txs).

extract_gl_tx(Sheet_name, Default_Currency, St0, Date0, [Item|Items], Txs) :-
	doc_value(Item, ic:date, Date1),
	Date1 = "ignore",
	!extract_gl_tx(Sheet_name, Default_Currency, St0, Date0, Items, Txs).

extract_gl_tx(Sheet_name, Default_Currency, _, _, [Item|Items], [Tx1|Txs]) :-
	doc_value(Item, ic:date, Date1),
	Date1 \= "ignore",
	check_date(Date1),
	!doc_new_uri(gl_input_st, St1),
	!doc_add_value(St1, transactions:description, Sheet_name, transactions),
	!doc_add_value(St1, transactions:gl_input_sheet_item, Item, transactions),
	!read_gl_line(Sheet_name, Default_Currency, Date1, St1, Item, Tx1),
	!extract_gl_tx(Sheet_name, Default_Currency, St1, Date1, Items, Txs).

 read_gl_line(Sheet_name, Default_Currency, Date, St, Item, Tx) :-
	push_context($>format(string(<$), 'extract GL input row from ~w', [$>sheet_and_cell_string(Item)])),
	!doc(Item, ic:account, Account_String),
	/* todo, support multiple description fields in transaction */
	(	doc_value(Item, ic:description, Description)
	->	true
	;	Description = Sheet_name),
	(	doc_value(Item, ic:debit, Debit_String)
	->	vector_from_string(Default_Currency, kb:debit, Debit_String, Debit_Vector)
	;	Debit_Vector = []),
	(	doc_value(Item, ic:credit, Credit_String)
	->	vector_from_string(Default_Currency, kb:credit, Credit_String, Credit_Vector)
	;	Credit_Vector = []),
	append(Debit_Vector, Credit_Vector, Vector),
	!gl_entry_account_specifier_parameters(Item, Parameters),
	!cf(find_account_by_specification(Account_String, Parameters, Account)),
	!c(make_transaction(St, Date, Description, Account, Vector, Tx)),
	pop_context.







 extract_reallocations(Txs) :-
 	(	doc($>request_data, ic_ui:reallocation, Gls)
 	->	(	maplist(!extract_reallocation, $>doc_list_items(Gls), Txs0),
			flatten(Txs0, Txs))
	;	Txs = []).

 extract_reallocation(Gl, Txs) :-
 	push_context($>format(string(<$), 'extract reallocation from: ~w', [$>sheet_and_cell_string(Gl)])),
 	!doc_value(Gl, ic:default_currency, Default_Currency0),
	!atom_string(Default_Currency, Default_Currency0),
	!doc_value(Gl, reallocation:items, List),
	!doc_list_items(List, Items),
	!doc_value(Gl, excel:has_sheet_name, Sheet_name),
	!doc_value(Gl, reallocation:account_A, Account_A_str),
	!atom_string(Account_A_atom, Account_A_str),
	!account_by_ui(Account_A_atom, Account_A),
	!doc_value(Gl, reallocation:account_A_is, Account_A_is),
	!doc(Account_A_is, reallocation:account_A_side, Side),
	!extract_reallocation_tx(Account_A, Side, Sheet_name, Default_Currency, none, none, Items, Txs),
	!check_trial_balance(
		$>result_has_property(l:exchange_rates),
		$>result_has_property(l:report_currency),
		$>result_has_property(l:end_date),
		Sheet_name,
	Txs),
	pop_context.


 extract_reallocation_tx(_,_,_,_,_,_,[],[]).

 extract_reallocation_tx(Account_A, Account_A_is, Sheet_name, Default_Currency, St0, Date0, [Item|Items], [Tx|Txs]) :-
	\+doc_value(Item, reallocation:date, _),
	(Date0 = none ->throw_string([Sheet_name, ': date missing']);true),
	(St0 = none ->throw_string([Sheet_name, ': format error']);true),
	!read_reallocation_line(Account_A_is, Sheet_name, Default_Currency, Date0, St0, Item, Tx),
	!extract_reallocation_tx(Account_A, Account_A_is, Sheet_name, Default_Currency, St0, Date0, Items, Txs).

extract_reallocation_tx(Account_A, Account_A_is, Sheet_name, Default_Currency, St0, Date0, [Item|Items], Txs) :-
	!doc_value(Item, reallocation:date, Date1),
	Date1 = "ignore",
	!extract_reallocation_tx(Account_A, Account_A_is, Sheet_name, Default_Currency, St0, Date0, Items, Txs).

extract_reallocation_tx(Account_A, Account_A_is, Sheet_name, Default_Currency, _, _, [Item|Items], [Tx1,Tx2|Txs]) :-
	!doc_value(Item, reallocation:date, Date1),
	Date1 \= "ignore",
	(	Date1 = date(_,_,_)
	->	check_date(Date1)
	;	throw_string([$>sheet_and_cell_string_for_property(Item, reallocation:date), ': error reading date. Got: ', Date1])),
	!doc_new_uri(gl_input_st, St1),
	!doc_add_value(St1, transactions:description, Sheet_name, transactions),
	!doc_add_value(St1, transactions:gl_input_sheet_item, Item, transactions),
	!reallocation_make_account_a_tx(Sheet_name, Default_Currency, Account_A, Account_A_is, Item, Date1, St1, Tx1),
	!read_reallocation_line(Account_A_is, Sheet_name, Default_Currency, Date1, St1, Item, Tx2),
	!extract_reallocation_tx(Account_A, Account_A_is, Sheet_name, Default_Currency, St1, Date1, Items, Txs).

reallocation_amount_vector(Default_Currency, Account_A_is, Item, Vector) :-
	(	doc_value(Item, reallocation:amount, Amount_string)
	->	true
	;	throw_string([$>sheet_and_cell_string_for_property(Item, reallocation:amount), ': missing "amount"'])),
	(	vector_from_string(Default_Currency, Account_A_is, Amount_string, Vector)
	->	true
	;	throw_string([$>sheet_and_cell_string_for_property(Item, reallocation:amount), ': error parsing "amount", got: ', Amount_string])).

reallocation_make_account_a_tx(Sheet_name, Default_Currency, Account_A, Account_A_is, Item, Date, St, Tx) :-
	(	doc_value(Item, reallocation:description, Description)
	->	true
	;	Description = Sheet_name),
	!reallocation_amount_vector(Default_Currency, Account_A_is, Item, Vector),
	!c(make_transaction(St, Date, Description, Account_A, Vector, Tx)).

 parametrized_account_from_prop(Item, Pred, Account) :-
 	(	doc(Item, Pred, Account_String)
 	->	true
	;	(
			sheet_and_cell_string(Item, Err_pos),
			throw_string(['entry at ', Err_pos, ': missing "account"'])
		)
	),
	!c(gl_entry_account_specifier_parameters(Item, Parameters)),
	catch(
		!c(find_account_by_specification(Account_String, Parameters, Account)),
		error(msg(E),_),
		throw_string([$>sheet_and_cell_string_for_property(Item, Pred), ': ', E])
	).


 read_reallocation_line(Account_A_is, Sheet_name, Default_Currency, Date, St, Item, Tx) :-
  	push_context($>format(string(<$), 'read_reallocation_line from: ~w', [$>sheet_and_cell_string(Item)])),
	parametrized_account_from_prop(Item, reallocation:account, Account),
	/* todo, support multiple description fields in transaction */
	(	doc_value(Item, reallocation:description, Description)
	->	true
	;	Description = Sheet_name),
	!reallocation_amount_vector(Default_Currency, Account_A_is, Item, Vector0),
	!vec_inverse(Vector0, Vector),
	!c(make_transaction(St, Date, Description, Account, Vector, Tx)),
	pop_context.


/*
todo, refactor: reallocation_tx_set_spec(Rows, [A_tx|Txs]) :-
	Txs = [B_Txs|Txs_rest],
	reallocation_tx_set(Rows, Rows_rest, B_Txs),
	reallocation_tx_set_spec(Rows_rest, Txs_rest).
*/


 gl_entry_account_specifier_parameters(Item, Parameters) :-
	findall(
		Parameter,
		(
			between(1, 5, I),
			doc(Item, $>atomic_list_concat([$>rdf_global_id(ic:param),I]), Parameter)
		),
		Parameters).

 find_account_by_specification(Account_string_uri, Parameters, Account) :-
 	value(Account_string_uri, Text),
 	push_context($>format(string(<$), 'interpret account specification string: ~q', [Text])),

 	once(c(!'use grammar to interpret text'(inp_account_specifier(Specifier), Text))),

	(	Specifier = name(Name_str)
	->	(	trim_string(Name_str, Name_str2),
			atom_string(Name, Name_str2),
			!account_by_ui(Name, Account))
	;	(
			Specifier = role(Role_spec),
			ct(
				$>format(string(<$), 'fill account role slots. role path: ~q specified in: ~w,  parameters: ~w', [Role_spec, $>sheet_and_cell_string(Account_string_uri), $>values(Parameters)]),
				!fill_slots(Role_spec, Parameters, Role_list)
			),
			!path_list_to_term(Role_list, Role),
			abrlt(Role, Account)
		)
	),
	pop_context.

inp_account_specifier(name(Name)) --> string_without("<!", Codes), {atom_codes(Name, Codes)}.
inp_account_specifier(role(Role)) --> `!`, inp_account_specifier2(Role), `!`.
inp_account_specifier(role(Role)) --> `!`, inp_account_specifier2(Role).
inp_account_specifier2([H]) --> inp_account_specifier2_part(H).
inp_account_specifier2([H|T]) --> inp_account_specifier2_part(H), `!`, inp_account_specifier2(T).
inp_account_specifier2_part(fixed(P)) --> string_without("<>!", Ps),{atom_codes(P, Ps)}.
inp_account_specifier2_part(slot(P)) --> `<`, string_without("<>!", Ps), `>`,{atom_codes(P, Ps)}.

out_account_specifier(name(Name)) --> string_without("<!", Codes), {atom_codes(Name, Codes)}.
out_account_specifier(role(Role)) --> `!`, out_account_specifier2(Role).
out_account_specifier(role(Role)) --> `!`, out_account_specifier2(Role), `!`.
out_account_specifier2([H]) --> out_account_specifier2_part(H).
out_account_specifier2([H|T]) --> out_account_specifier2_part(H), `!`, out_account_specifier2(T).
out_account_specifier2_part(fixed(P)) --> {atom_codes(P, Ps)}, Ps.
out_account_specifier2_part(slot(P)) --> `<`, {atom_codes(P, Ps)}, Ps.




fill_slots([], [], []) :- !.

fill_slots([slot(_)|Slots], [Param|Params], [P2|RoleT]) :-
	!fill_slots(Slots, Params, RoleT),
	!,
	atom_string(P2, $>!value(Param)).

fill_slots([fixed(Part)|Slots], Params, [Part|RoleT]) :-
	atom(Part),
	!fill_slots(Slots, Params, RoleT),
	!.

fill_slots([], [Param|_], []) :-
%gtrace,
	throw_string([
		'no slot for parameter "', $>!value(Param), '", specified in ', $>sheet_and_cell_string(Param)
	]).

fill_slots([H|_], [], []) :-
	throw_string([
		'no parameter for slot: "', H, '"'/*,' in account role path:\n'
		Path_str,
		'\nspecified in ', $>value_sheet_and_cell_string(Path)*/
		]).

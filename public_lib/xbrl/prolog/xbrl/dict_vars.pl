


/* take a list of variables, produce a dict with lowercased variable names as keys, and variables themselves as values.
see plunit/utils for examples*/
user:goal_expansion(
	dict_from_vars(Dict, Vars_List), Code
) :-
	maplist(var_to_kv_pair, Vars_List, Pairs),
	Code = dict_create(Dict, _, Pairs).

user:goal_expansion(
	dict_from_vars(Dict, Name, Vars_List), Code
) :-
	maplist(var_to_kv_pair, Vars_List, Pairs),
	Code = dict_create(Dict, Name, Pairs).

var_to_kv_pair(Var, Pair) :-
	var_property(Var, name(Name)),
	downcase_atom(Name, Name_Lcase),
	Pair = Name_Lcase-Var.



/* take a list of variables, unify them with values of Dict, using lowercased names of those variables as keys.
see plunit/utils for examples*/
user:goal_expansion(
	dict_vars(Dict, Tag, Vars_List), Code
) :-
	Code = (is_dict(Dict, Tag), Code0),
	dict_vars_assignment(Vars_List, Dict, Code0).

user:goal_expansion(
	dict_vars(Dict, Vars_List), Code
) :-
	dict_vars_assignment(Vars_List, Dict, Code).
	%(dict_vars_assignment(Vars_List, Dict, Code) -> true ; (format(user_error, 'xxxxx', []))).

dict_vars_assignment([Var|Vars], Dict, Code) :-
	Code = (Code0, Codes),
	%Code0 = (debug(dict_vars, '~w', [Key]), get_dict(Key_Lcase, Dict, Var)),
	Code0 = ((debug(dict_vars, '~w', [Key]), (get_dict(Key_Lcase, Dict, Var)->true;throw(existence_error(key, Key_Lcase, Dict))))),
	%Code0 = get_dict_ex(Key_Lcase, Dict, Var), % not supported in some versions?
    (
        (
            var_property(Var, name(Key)),
            downcase_atom(Key, Key_Lcase)
        )
    ->
        true
    ;
        true%(writeq(Code), nl, nl/*, Key_Lcase = yy*/)
    ),
    dict_vars_assignment(Vars, Dict, Codes).

dict_vars_assignment([], _, true).




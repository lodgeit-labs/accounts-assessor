% ===================================================================
% Project:   LodgeiT
% Module:    accounts.pl
% Date:      2019-06-02
% ===================================================================

:- module(accounts, [
		/*The public api.*/
		/*The rest of the codebase should never deal with account terms directly, only handle them by id or role, so i am leaving out the "_id" where possible. 
		All these predicates take and return id's or roles, and require that Accounts is passed to them as first argument*/
		account_in_set/3, 
		account_by_role/3, 
		account_by_role_nothrow/3, 
		account_child_parent/3,
		account_exists/2,
		account_role_by_id/3,
		account_detail_level/3,
		account_normal_side/3,
		sub_accounts_upto_level/4,
		child_accounts/3,
		/*extract account tree specified in request xml*/
		extract_account_hierarchy/2, 
		check_account_parent/2,

		/*The private api.*/
		/*accessors of account term fields*/
		account_id/2,
		account_role/2,
		account_parent/2, 
		account_detail_level/2,
		/*you don't need this*/
		account_term_by_role/3,
		write_accounts_json_report/1]).

:- use_module(library(http/http_client)).
:- use_module(library(record)).
:- use_module(library(xpath)).
:- use_module('utils', [inner_xml/3, trim_atom/2,pretty_term_string/2, throw_string/1, is_uri/1]).
:- use_module('files', [server_public_url/1, absolute_tmp_path/2, write_tmp_json_file/2]).
:- use_module(library(http/http_dispatch), [http_safe_file/2]).
:- use_module(library(http/http_open), [http_open/3]).
% :- use_module(library(yall)).

:- record account(id, parent, role, detail_level).


/*
from what i understand, both account names and account numbers can change
at least the logic does not seem to ever need to care about the structure of the tree, only about identifying appropriate accounts
so what i see we need is a user interface and a simple xml schema to express associations between accounts and their roles in the system
the roles can have unique names, and later URLs, in the whole set of programs
.
<role name="Livestock sales revenue" account="4321">
or rather <account id="xxxx" role="Financial_Investments/Realized_Gains">...

mostly it is a matter of creating a user interface to specify these associations
the program can also create sub-accounts from the specified account in runtime as needed, for example for livestock types
then each account hierarchy can come with a default set of associations*/

account_exists(Accounts, Id) :-
	account_id(Account, Id),
	memberchk(Account, Accounts).
	
account_detail_level(Accounts, Id, Detail_Level) :-
	account_term_by_id(Accounts, Id, Account),
	account_detail_level(Account, Detail_Level).
	
% Relates an account to an ancestral account or itself
account_in_set(Accounts, Account_Id, Root_Account_Id) :-
	Account_Id = Root_Account_Id;
	(
		account_id(Child_Account, Child_Id),
		account_parent(Child_Account, Root_Account_Id),
		member(Child_Account, Accounts),
		account_in_set(Accounts, Account_Id, Child_Id)
	).

account_child_parent(Accounts, Child_Id, Parent_Id) :-
	(
		nonvar(Child_Id),
		account_term_by_id(Accounts, Child_Id, Child),
		account_parent(Child, Parent_Id)
	)
	;
	(
		nonvar(Parent_Id),
		member(Child, Accounts),
		account_id(Child, Child_Id),
		account_parent(Child, Parent_Id)
	).

account_direct_children(Accounts, Parent, Children) :-
	findall(
		Child,
		account_child_parent(Accounts, Child, Parent),
		Children
	).
	
account_by_role_nothrow(Accounts, Role, Account_Id) :-
	account_role(Account, Role),
	account_id(Account, Account_Id),
	member(Account, Accounts).
/* TODO: account_by_role_nothrow is legitimate. but we also want account_by_role(_throw). But it shouldn't cut after first result, otherwise we unnecessarily break order invariance in calling code. */
account_by_role(Accounts, Role, Account_Id) :-
	(
		account_by_role_nothrow(Accounts, Role, Account_Id)
	->
		true
	;
		(
			pretty_term_string(Accounts, Accounts_Str),
			term_string(Role, Role_Str),
			format(atom(Err), 'accounts: ~w \naccount not found in hierarchy: ~w\n', [Accounts_Str,  Role_Str]),
			format(user_error, Err, []),
			throw_string(Err)
		)
	).

account_term_by_role(Accounts, Role, Account) :-
	member(Account, Accounts),
	account_role(Account, Role).
	
account_term_by_id(Accounts, Id, Account) :-
	account_id(Account, Id),
	member(Account, Accounts).

account_role_by_id(Accounts, Id, Role) :-
	account_term_by_id(Accounts, Id, Account),
	account_role(Account, Role).

	
extract_account_hierarchy(Request_DOM, Account_Hierarchy) :-
	% writeln(Request_DOM),
	findall(
		DOM,
		xpath(Request_DOM, //reports/balanceSheetRequest/accountHierarchy, DOM), 
		DOMs
	),
	(
		DOMs = []
	->
		add_accounts(element(_,_,['default_account_hierarchy.xml']), Account_Hierarchy)
	;
		(
			maplist(add_accounts, DOMs, Accounts),
			flatten(Accounts, Account_Hierarchy_Unsorted),
			sort(Account_Hierarchy_Unsorted, Account_Hierarchy)
		)
	).

/*
	would be simplified by a generic "load_file" or w/e, that can take either a URL
	or a filepath and returns the contents. then we just differentiate based on whether
	it's a taxonomy or a simple accounts hierarchy

	would be even more simplified if we differentiated between <accounts> and <taxonomy> tags
	so that we're not trying to dispatch by inferring the file contents
	
	<taxonomy> tag:
		we'll probably end up extracting more info from the taxonomies later anyway
		should only be one taxonomy tag
		because: should only be one main taxonomy file that does the linking to other taxonomy files (if any)
			(until we have some use-case for "supporting multiple taxonomies" ?)
		arelle doesn't care whether you send it a filepath or URL

	<accounts> tag:
		now only two cases:
			1) DOM = element(_,_,_)
			2) [Atom] = DOM
				then just generic "load_file(Atom, Contents), extract_simple_account_hierarchy(Contents, Account_Hierarchy)"

*/


% "read_links_from_accounts_tag"
add_accounts(DOM, Accounts) :-
	% "read_dom_from_accounts_tag"
	(
		%is it a tree of account tags? use it
		DOM = element(_,_,[element(_,_,_)|_])
	->
		Accounts_DOM = DOM
	;
		(
			element(_,_,[Atom]) = DOM,
			trim_atom(Atom, Path),
			(
				is_uri(Path)
			->
				(
					accounts_dom_from_url(Path, Accounts_DOM)
				)
			;
				% Path not recognized as a URI, assume it represents a local filepath
				(
					accounts_dom_from_file_path(Path, Accounts_DOM)
				)
			)
		)
	),
	% "read_links_from_accounts_dom"
	extract_account_hierarchy2(Accounts_DOM, Accounts).

/*server_public_url(Server_Url),
atomic_list_concat([Server_Url, '/taxonomy/basic.xsd'],Taxonomy_URL),
format(user_error, 'loading default taxonomy from ~w\n', [Taxonomy_URL]),
extract_account_hierarchy_from_taxonomy(Taxonomy_URL,Dom)*/

accounts_dom_from_url(URL, Accounts_DOM) :-
	(
		fetch_account_hierarchy_from_url(URL, Accounts_DOM)
	->
		true
	;
		(
			arelle(taxonomy, URL, Accounts_DOM)
		)
	).

% NOTE: we have to load an entire taxonomy file just to determine that it's not a simple XML hierarchy
fetch_account_hierarchy_from_url(Account_Hierarchy_URL, Account_Hierarchy_DOM) :-
	/*fixme: throw something more descriptive here and produce a human-level error message at output*/
	setup_call_cleanup(
        http_open(Account_Hierarchy_URL, In, []),
		load_structure(In, File_DOM, [dialect(xml),space(remove)]),
        close(In)
    ),

	xpath(File_DOM, //accountHierarchy, Account_Hierarchy_DOM).

% if we do more XBRL taxonomy processing we'll probably be adding more cases to `arelle`
arelle(taxonomy, Taxonomy_URL, Account_Hierarchy_DOM) :-
	setup_call_cleanup(
		% should be activating the venv here
		process_create('../python/venv/bin/python3',['../python/src/account_hierarchy.py',Taxonomy_URL],[stdout(pipe(Out))]),
		(
			load_structure(Out, File_DOM, [dialect(xml),space(remove)]),
			absolute_tmp_path('account_hierarchy_from_taxonomy.xml', FN),
			open(FN, write, Stream),
			xml_write(Stream, File_DOM, [])
			% shouldn't we be closing FN here?
		),
		close(Out)
	),
	% should probably just pass back the whole File_DOM so that it can be treated homogeneously
	% with other sources of account hierarchy XMLs, since we keep repeating this line

	xpath(File_DOM, //accountHierarchy, Account_Hierarchy_DOM).

accounts_dom_from_file_path(File_Path, Accounts_DOM) :-
	http_safe_file(File_Path, []),
	absolute_file_name(my_static(File_Path), Absolute_Path, [ access(read) ]),
	(
		load_xml(Absolute_Path, File_DOM, [space(remove)]),
		xpath(File_DOM, //accountHierarchy, Accounts_DOM)
	->
		true
	;
		arelle(taxonomy, Absolute_Path, Accounts_DOM)
	).


% ------------------------------------------------------------------
% extract_account_hierarchy2/2
%
% Load Account Hierarchy terms from Dom
% ------------------------------------------------------------------

extract_account_hierarchy2(Account_Hierarchy_Dom, Account_Hierarchy) :-
	findall(Link, yield_accounts(Account_Hierarchy_Dom, Link), Account_Hierarchy0),
	sort(Account_Hierarchy0, Account_Hierarchy).

 
% extracts and yields all accounts one by one
yield_accounts(element(Parent_Name,_,Children), Link) :-
	member(Child, Children), 
	Child = element(Child_Name,_,_),
	(
		(
			/* TODO: extract role, if specified */
			Role = ('Accounts' / Child_Name),
			Link = account(Child_Name, Parent_Name, Role, 0)
		)
		;
		(
			% recurse on the child
			yield_accounts(Child, Link)
		)
	).

/* @Bob fixme, we should be getting this info from the taxonomy */
account_normal_side(Account_Hierarchy, Name, credit) :-
	member(Credit_Side_Account_Id, ['Liabilities', 'Equity', 'Revenue']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(Account_Hierarchy, Name, debit) :-
	member(Credit_Side_Account_Id, ['Expenses']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(Account_Hierarchy, Name, credit) :-
	member(Credit_Side_Account_Id, ['Earnings', 'NetIncomeLoss']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(_, _, debit).


sub_accounts_upto_level(Accounts, Parent, Level, Sub_Accounts) :-
	sub_accounts_upto_level2(Accounts, [Parent], Level, [], Sub_Accounts).

sub_accounts_upto_level2(_, _, 0, Results, Results).
sub_accounts_upto_level2(_, [], _, Results, Results).

sub_accounts_upto_level2(Accounts, [Parent|Parents], Level, In, Out) :-
	Level > 0,
	New_Level is Level - 1,
	account_direct_children(Accounts, Parent, Children),
	append(In, Children, Mid),
	sub_accounts_upto_level2(Accounts, Children, New_Level, Mid, Mid2),
	sub_accounts_upto_level2(Accounts, Parents, Level, Mid2, Out).

	
child_accounts(Accounts, Parent_Account, Child_Accounts) :-
	sub_accounts_upto_level(Accounts, Parent_Account, 1, Child_Accounts).


/*
check that each account has a parent. Together with checking that each generated transaction has a valid account,
this should ensure that the account balances we are getting with the new taxonomy is correct*/
check_account_parent(Accounts, Account) :-
	account_id(Account, Id),
	account_parent(Account, Parent),
	(
		Parent == 'accountHierarchy'
	->
		true
	;
		(
			account_exists(Accounts, Parent)
		->
			true
		;
			throw_string(['account "', Id, '" parent "', Parent, '" missing.'])
		)
	).

write_accounts_json_report(Accounts) :-	
	maplist(account_to_dict, Accounts, Dicts),
	write_tmp_json_file('accounts.json', Dicts).

account_to_dict(Account, Dict) :-
	Dict = _{
		id: Id,
		parent: Parent,
		role: Role,
		detail_level: Detail_Level
	},
	Account = account(Id, Parent, Role, Detail_Level).

	
	

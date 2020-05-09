
:- comment(meta(this_file), """

	step -1:
		implement ":- comment"



	step 0:
		add support for multiline strings in prolog



	step 1:
		express aspect information within prolog code


""").


% store_access_and_manipulation

add_atoms(S2,P2,O2,G2) :-
		ground(spog(S2,P2,O2,G2)),


	aspect('the path through the store data-structure',

		% get the_theory global
		b_getval(the_theory, Ss)
		%, ie a dict from subjects to pred-dicts

	),

	aspect('the path through the store data-structure',

		% does it contain the subject?
		(	Ps = Ss.get(S2)
		%	the it's a dict from preds to graphs
		->	true
		;	(
				Ps = _{},
				b_setval(the_theory, Ss.put(S2, Ps))
			)
		),
		(	Gs = Ps.get(P2)
		->	true
		;	(
				Gs = _{},
				b_set_dict(P2, Ss, Ps.put(P2, Gs))
			)
		),
		Gs.get(

		(	Os = Ps.get(G2)
		->	true
		;	(
				Os = _,
				b_set_dict(G2, Ps, Os)
			)
		),
		rol_member(O2, Os).








:- comment(x, """

	step 999:
		hide cruft with a projectional editor


""").

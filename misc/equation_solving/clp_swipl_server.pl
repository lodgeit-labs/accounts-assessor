
process_constraints :-
	read_constraint(C),
	(	C = done
	->	true
	;	(
			(
				(	apply_constraint(C),
					!answer(success)
				)
			;	!answer(fail)
			)
		),
		process_constraints
	).


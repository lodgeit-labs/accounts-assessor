
# todo: gl json export on the python side.

# would work alongside gl_export_enrichment.pl
#
# def generate_gl_json(g):
# 	Entry = _{source: S, transactions: T},
#	where/how to handle rounding though? probably on the prolog side:
#		currently we haev: round_term(2, Json, Report_Dict)
#		instead, we'd just round individual properties as needed, and assert, ie, transaction_vector_rounded
#	s_transaction_to_dict(T, D) :- ...

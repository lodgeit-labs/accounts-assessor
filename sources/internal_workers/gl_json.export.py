
# todo: gl json export on the python side.

# would work alongside gl_export_enrichment.pl
#
def generate_gl_json(g):
	rd = request_data(g)
	txs = g.object(rd, 'ic:transactions')
	txs = value(txs)
	txs = list_from_rdf(txs)
	dict = defaultdict(list)
	for tx in txs:
		origin = g.object(tx, 'ic:origin')
		dict[origin].append(tx_json(tx))
	json = []
	for k, v in dict.items():
		json.append({'source': tx_origin_json(k), 'transactions': v}



#	where/how to handle rounding though? probably on the prolog side:
#		currently we haev: round_term(2, Json, Report_Dict)
#		instead, we'd just round individual properties as needed, and assert, ie, transaction_vector_rounded
#	s_transaction_to_dict(T, D) :- ...


	/*
	for each report_entry:
	
	l:balance_rendering_for_dashdash rdf:comment "rounded to two digits. If balance is an empty vector, this is a numerical 0, otherwise the numerical value in report currency, in normal side. In case of a balance containing different units than just report currency, a string".

	an integer ordering key is added post-hoc, obtained by flattening the tree
	then, the list can be queried with sparql with ORDER BY

	*/

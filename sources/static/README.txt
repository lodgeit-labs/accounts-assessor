Account Hierarchy Taxonomy is currently in XML format. Ultimate goal is to convert it to XBRL Taxonomy (Schema).

This Account Hierarchy is loaded in the process_xml_ledger_request.pl while handling the ledger request to generate the ledger response.
The predicate process_xml_ledger_request loads the taxonomoy, which is used to preprocess everything and ultimately structure the response generated in balance_sheet_at predicate in ledger.pl.

see also accounts.pl
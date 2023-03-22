

extract_request_details(Dom) :-
	xpath(Dom, //reports/balanceSheetRequest/company/clientcode, Client_code),
	get_time(TimeStamp),
	stamp_date_time(TimeStamp, DateTime, 'UTC'),
	result(Result),
	doc_add(Result, l:timestamp, DateTime),
	request(Request),
	doc_add(Request, l:client_code, Client_code).


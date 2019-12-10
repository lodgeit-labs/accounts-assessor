:- use_module(library(xpath)).

:- dynamic doc_data/3.
:- dynamic concept_data/3.
:- dynamic doc_concept/2.

process_xml_hirepurchase_request(_FileNameIn, DOM, _Reports) :-
	xpath(DOM, //request/solve, element(_,_,Documents)),
	solve(Documents, Result_Documents),
	xml_write(element(response,[],Result_Documents), []).

fresh_bnode(Bnode) :-
	gensym(bn, Bnode).

template(hp_arrangement, hp_arrangement_template(contractNumber, cashPrice, beginDay, interestRate, installments)).




extract_by_template(Document, Document_Type, Data) :-
	template(Document_Type, Document_Template),
	Document_Template =.. [_|Fields],
	findall(
		Value,
		(
			member(Field, Fields),
			xpath(Document, //document/Field, element(_,_,[Value]))
		),
		Values
	),
	Data =.. [Document_Type|Values].

contents_value( [], _).
contents_value( [ Value ], Value).


assert_document(Document, Document_Node) :-
	Document = element(document, [type=Document_Type], Document_Data),
	fresh_bnode(Document_Node),
	assertz(doc_data(Document_Node, 'a', Document_Type)),
	member(element(Field, _, Contents), Document_Data),
	contents_value(Contents, Value),
	assertz(doc_data(Document_Node, Field, Value)).

assert_documents(Documents, Document_Nodes) :-
	findall(
		Document_Node,
		(
			member(Document, Documents),
			assert_document(Document, Document_Node)
		),
		Document_Nodes
	).

retract_documents(Document_Nodes) :-
	findall(
		_,
		(
			member(Document_Node, Document_Nodes),
			retract(doc_data(Document_Node, _, _))
		),
		_
	).
retract_concepts(Concept_Nodes) :-
	findall(
		_,
		(
			member(Concept_Node, Concept_Nodes),
			retract(concept_data(Concept_Node, _, _))
		),
		_
	).

doc_concept_association('HirePurchaseArrangement', hp_arrangement).
doc_concept_association('HirePurchaseSummary', hp_arrangement).

associate_concept(Document_Node, Concept_Node) :-
	

associate_concepts([], []).
associate_concepts([Document_Node | Document_Nodes], [Concept_Node | Concept_Nodes]) :-
	associate_concept(Document_Node, Concept_Node),
	associate_concepts(Document_Nodes, Concept_Nodes).

resolve_concept(Concept_Node) :-
	concept_data(Concept_Node, 'a', Concept_Type),
	findall(
		_,
		(
			field(Concept_Type, Field, Resolver),
			(
				call(Resolver, Concept_Node, Value)
			->
				assertz(concept_data(Concept_Node, Field, Value))
			;
				assertz(concept_data(Concept_Node, Field, _))
			)
		),
		_
	).
	

resolve_concepts([]).
resolve_concepts([Concept_Node | Concept_Nodes]) :-
	resolve_concept(Concept_Node),
	resolve_concepts(Concept_Nodes).

solve(Documents, Result_Documents) :-
	% assert the query documents
	assert_documents(Documents, Document_Nodes),

	% associate query documents to concepts
	associate_concepts(Document_Nodes, Concept_Nodes),

	% resolve concept values
	resolve_concepts(Concept_Nodes),

	% for each missing document field, query for that value
	documents_fill_missing(Documents, Result_Documents),
	%solve2(Documents, Result_Documents),

	% retract 
	retract_documents(Document_Nodes),
	retract_concepts(Concept_Nodes).

documents_fill_missing([], []).
documents_fill_missing([Document | Documents], [Result_Document | Result_Documents]) :-
	document_fill_missing(Document, Result_Document),
	documents_fill_missing(Documents, Result_Documents).

document_fill_missing(element(document, [type=Document_Type], Fields), element(document, Document_Type, Result_Fields)) :-
	doc_data(Document_Node, 'a', Document_Type),
	fill_missing_fields(Document_Node, Fields, Result_Fields).

fill_missing_fields(_, [], []).
fill_missing_fields(Document_Node, [Field | Fields], [Result_Field | Result_Fields]) :-
	fill_missing_field(Document_Node, Field, Result_Field),
	fill_missing_fields(Document_Node, Fields, Result_Fields).

% just use given fields
fill_missing_field(_, element(Field, Attrs, [Value]), element(Field, Attrs, [Value])) :- !.
fill_missing_field(Document_Node, element(Field, Attrs, []), element(Field, Attrs, [Value])) :-
	doc_data(Document_Node, conceptNode, Concept_Node),
	doc_data(Document_Node, 'a', Document_Type),
	concept_data(Concept_Node, 'a', Concept_Type),
	field_association(Document_Type, Field, Concept_Type, Concept_Field),
	concept_data(Concept_Node, Concept_Field, Value).
	
/*
solve2([], []).
solve2([Document | Documents] , [Result_Document | Result_Documents]) :-
	solve_document(Document, Result_Document),
	solve2(Documents, Result_Documents).

solve_document(element(document, [type=Document_Type], Fields), element(document, Document_Type, Result_Fields)) :-
	doc_data(Document_Node, 'a', Document_Type),
	solve_fields(Document_Node, Fields, Result_Fields).

solve_fields(_, [], []).
solve_fields(Document_Node, [Field | Fields], [Result_Field | Result_Fields]) :-
	solve_field(Document_Node, Field, Result_Field),
	solve_fields(Document_Node, Fields, Result_Fields).

% just use given fields
solve_field(_, element(Field, Attrs, [Value]), element(Field, Attrs, [Value])).

% fill in missing fields
solve_field(Document_Node, element(Field, Attrs, []), element(Field, Attrs, [Value])) :-
	resolve(Document_Node, Field, Value).
*/

/*

document_concept('HirePurchaseArrangement', hp_arrangement).
document_concept('HirePurchaseSummary', hp_arrangement).



% given concept type, find associated concept instances
% given concept instance, find associated concept type
% given concept type, find associated document types
% given document type, find associated concept types
% given concept instance, find associated document instances
% given document instance, find associated concept instances
% given document type, find associated document instances
% given document instance, find associated document type

% concept_type     -- 1:N -- concept_instance
% document_type    -- 1:N -- document_instance
% concept_type     -- N:N -- document_type
% concept_instance -- N:N -- document_instance

% XML -> doc_data assertions
% doc_data assertions -> concept_data
% concept_data -> resolve

resolve(Object, Field, Value) :-
	doc_data(Object, Field, Value).


% transferring fields between HirePurchaseArrangement and HirePurchaseSummary
% should instead transfer fields between each document and the concept that document represents, and then
% as a second stage, transfer fields from the concept to each document representing it.
resolve(Document, Field, Value) :-
	doc_data(Document, 'a', 'HirePurchaseSummary'),
	doc_data(Document, contractNumber, ContractNumber),
	doc_data(HP_Arrangement, 'a', 'HirePurchaseArrangement'),
	doc_data(HP_Arrangement, contractNumber, ContractNumber),
	doc_data(HP_Arrangement, Field, Value).

% resolve input documents into concept
% resolve concept fields into full concept
% resolve full concept into result document


resolve(HP_Arrangement, contractNumber, Value) :-
	resolve(HP_Arrangement, 'a', hp_arrangement),
	doc_data(HP_Arrangement, contractNumber, Value).

resolve(HP_Arrangement, cashPrice, Value) :-
	resolve(HP_Arrangement, a, hp_arrangement),
	doc_data(HP_Arrangement, cashPrice, Value).

resolve(HP_Arrangement, beginDate, Value) :-
	resolve(HP_Arrangement, a, hp_arrangement),
	doc_data(HP_Arrangement, beginDate, Value).

resolve(HP_Arrangement, paymentType, Value) :-
	resolve(HP_Arrangement, a, hp_arrangement),
	doc_data(HP_Arrangement, paymentType, Value).
*/


query(concept_data(C, S, P, O)) :-
	(
		found_data(C, S, P, O)
	->
		true
	;
		query2(concept_data(C, S, P, O))
	).

query2(concept_data(C, S, P, O)) :-
	implication(Head, Body),
	member(concept_data(C, S, P, O), Head),
	findall(
		_,
		(
			member(Goal, Body),
			call(Goal)
		),
		_
	).
	
/*

Derive installments from HP arrangement
Derive necessary duration from HP arrangement
Derive total amount paid from HP arrangement
Derive missing interest rate, when given information on any single installment
Find interest rate that would cause HP arrangement to have a particular duration
Balloon payments
Payment types
Generate corrections:
* Correct duplicate payment
* Correct incorrect account payment
* Correct incorrect amount payment
* Correct missing payment
Report inconsistencies:
* ...


*/

% fields should probably be Typed..
field(hp_arrangement, contractNumber).
field(hp_arrangement, cashPrice).
field(hp_arrangement, beginDay).
field(hp_arrangement, endDay).
field(hp_arrangement, duration).
field(hp_arrangement, periodDuration).
field(hp_arrangement, numberOfInstallments).
field(hp_arrangement, interestRate).
field(hp_arrangement, installment).
field(hp_arrangement, totalInterest).
field(hp_arrangement, totalPayment).
field(hp_arrangement, account).

% ontology alignment
field_association('HirePurchaseArrangement', contractNumber, hp_arrangement, contractNumber).
field_association('HirePurchaseArrangement', cashPrice, hp_arrangement, cashPrice).
field_association('HirePurchaseArrangement', beginDay, hp_arrangement, beginDay).
field_association('HirePurchaseArrangement', paymentType, hp_arrangement, paymentType).
field_association('HirePurchaseArrangement', interestRate, hp_arrangement, interestRate).
field_association('HirePurchaseArrangement', numberOfInstallments, hp_arrangement, numberOfInstallments).
field_association('HirePurchaseArrangement', totalInterest, hp_arrangement, totalInterest).
field_association('HirePurchaseArrangement', totalPayments, hp_arrangement, totalPayments).



resolver(_, Field, standard_resolver(Field)).
resolver(hp_arrangement, installment, hp_arrangement_installment).
resolver(hp_arrangement, totalInterest, hp_arrangement_total_interest).
resolver(hp_arrangement, totalPayment, hp_arrangement_total_payment).

standard_resolver(Field, Concept_Node, Value) :-
	concept_data(Concept_Node, 'a', Concept_Type),
	field_association(_, Document_Field, Concept_Type, Field),
	doc_data(Document_Node, conceptNode, Concept_Node),
	doc_data(Document_Node, Document_Field, Value).

	
	
/*
% the following hp fields are parameterized by a given date;
% not sure how to handle the parameterization yet.
% fallback option?
% it's an extension of an hp_arrangement, it has all the same fields as an hp_arrangement, and then some more that
% can only be derived relative to the given date.

field(hp_arrangement_at_date, Field) :-
	field(hp_arrangement, Field).
field(hp_arrangement_at_date, date).
field(hp_arrangement_at_date, currentPeriod).
field(hp_arrangement_at_date, payments).
field(hp_arrangement_at_date, remainingInstallments).
field(hp_arrangement_at_date, pastInstallments).
field(hp_arrangement_at_date, interestFormula).
field(hp_arrangement_at_date, currentLiabilities).
field(hp_arrangement_at_date, currentUnexpiredInterest).
field(hp_arrangement_at_date, noncurrentLiabilities).
field(hp_arrangement_at_date, noncurrentUnexpiredInterest).
field(hp_arrangement_at_date, repaymentBalance).
field(hp_arrangement_at_date, unexpiredInterest).
field(hp_arrangement_at_date, liabilityBalance).
*/

hp_arrangement_installment(HP_Arrangement, Record) :-
	concept_data(HP_Arrangement, 'a', hp_arrangement),
	concept_data(HP_Arrangement, numberOfInstallments, Number_Of_Installments),
	% get installment node somehow...
	Current_Record_Number = 0,
	hp_arr_cash_price(Arrangement, Current_Closing_Balance),
	hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_arr_begin_day(Arrangement, Current_Inst_Day),
	hp_rec_aux(Current_Record_Number, Current_Closing_Balance, Interest_Rate, Current_Inst_Day, Installments_Hd, Next_Record),
	(Record = Next_Record; hp_rec_record(Next_Record, Installments_Tl, Record)).
	

hp_arrangement_total_payment_from(HP_Arrangement, From_Day, Total_Payment) :-
	concept_data(HP_Arrangement, 'a', hp_arrangement),
	findall(
		Installment_Amount,
		(
			concept_data(HP_Arrangement, installment, hp_record(_,_,_,_,Installment_Amount,_,_,Closing_Day)),
			From_Day =< Closing_Day
		),
		Installment_Amounts
	),
	sum_list(Installment_Amounts, Total_Payment).	

hp_arrangement_total_payment(HP_Arrangement, Total_Payment) :-
	concept_data(HP_Arrangement, 'a', hp_arrangement),
	concept_data(HP_Arrangement, beginDay, Begin_Day),
	hp_arrangement_total_payment_from(HP_Arrangement, Begin_Day, Total_Payment).

example(element(request, _, [element(solve, _, [
	element(document, [type='HirePurchaseArrangement'], [
		element(contractNumber, [], ['ACAP426204.1.0']),
		element(cashPrice, [], [5953.20]),
		element(beginDate, [], [date(2015,1,16)]),
		element(paymentType, [], ['arrears']),
		element(interestRate, [], [13.00]),
		element(numberOfInstallments, [], [36]),
		element(totalPayments, [], [])
	]),
	element(document, [type='HirePurchaseSummary'], [
		element(contractNumber, [], ['ACAP426204.1.0']),
		element(date, [], [date(2015,1,16)]),
		element(currentLiability, [], []),
		element(noncurrentLiability, [], []),
		element(currentUnexpiredInterest, [], []),
		element(noncurrentUnexpiredInterest, [], [])
	]),
	element(document, [type='HirePurchaseSummary'], [
		element(contractNumber, [], ['ACAP426204.1.0']),
		element(date, [], [date(2015,1,16)]),
		element(repaymentLiability, [], []),
		element(unexpiredInterest, [], [])
	]),
	element(document, [type='HirePurchaseSummary'], [
		element(contractNumber, [], ['ACAP426204.1.0']),
		element(date, [], [date(2015,1,16)]),
		element(liability, [], [])
	])
])])).


% The purpose of the following program is to derive information about a given hire
% purchase arrangement. That is, this program will tell you what the closing balance of
% the hire purchase account is after a particular installment has been paid. It will tell
% you how much interest you will have paid by the close of the arrangement. And it will
% tell you other relevant information.

% This program is part of a larger system for validating and correcting balance sheets.
% More precisely, accounting principles require that the transactions that occur in a hire
% purchase arrangement are summarized in balance sheets. This program calculates those
% summary values directly from the original data and ultimately will be expected to add
% correction entries to the balance sheet when it is in error.

% Predicate to generate a range of values through stepping forwards from a start point

range(Start, _, _, Value) :-
	Start = Value.

range(Start, Stop, Step, Value) :-
	Next_Start is Start + Step,
	Next_Start < Stop,
	range(Next_Start, Stop, Step, Value).

maximum(Var, Query, Max) :-
	findall(Var, Query, Answers),
	max_list(Answers, Max).

minimum(Var, Query, Min) :-
	findall(Var, Query, Answers),
	min_list(Answers, Min).

% Predicates for asserting the fields of a hire purchase installment

% The date the installment is to be paid
hp_inst_day(hp_installment(Day, _), Day).
% The amount that constitutes the installment
hp_inst_amount(hp_installment(_, Installment), Installment).

% Predicates for asserting the fields of a hire purchase arrangement

% An identifier for a given hire purchase arrangement
hp_arr_contract_number(hp_arrangement(Contract_Number, _, _, _, _), Contract_Number).
% The opening balance of the whole arrangement
hp_arr_cash_price(hp_arrangement(_, Cash_Price, _, _, _), Cash_Price).
% The beginning day of the whole arrangement
hp_arr_begin_day(hp_arrangement(_, _, Begin_Day, _, _), Begin_Day).
% The stated annual interest rate of the arrangement
hp_arr_interest_rate(hp_arrangement(_, _, _, Interest_Rate, _), Interest_Rate).
% A chronologically ordered list of purchase arrangement installments. The latter
% installments where the account balance is negative are ignored.
hp_arr_installments(hp_arrangement(_, _, _, _, Installments), Installments).

/*
hirepurchase_arrangements sheet columns:
Contract_Number,Cash_Price,Begin_Day,Interest_Rate
*/

% Predicates for asserting the fields of a hire purchase record

% Records are indexed in chronological order
hp_rec_number(hp_record(Record_Number, _, _, _, _, _, _, _), Record_Number).
% The balance of the payment at the beginning of the given period
hp_rec_opening_balance(hp_record(_, Opening_Balance, _, _, _, _, _, _), Opening_Balance).
% The interest rate being applied to the opening balance
hp_rec_interest_rate(hp_record(_, _, Interest_Rate, _, _, _, _, _), Interest_Rate).
% The calculated interest for the given period
hp_rec_interest_amount(hp_record(_, _, _, Interest_Amount, _, _, _, _), Interest_Amount).
% The amount being paid towards the good in the given period
hp_rec_installment_amount(hp_record(_, _, _, _, Installment_Amount, _, _, _), Installment_Amount).
% The balance of the payment at the end of the given period
hp_rec_closing_balance(hp_record(_, _, _, _, _, Closing_Balance, _, _), Closing_Balance).
% The opening day of the given record's period
hp_rec_opening_day(hp_record(_, _, _, _, _, _, Opening_Day, _), Opening_Day).
% The closing day of the given record's period
hp_rec_closing_day(hp_record(_, _, _, _, _, _, _, Closing_Day), Closing_Day).

% A predicate for generating Num installments starting at the given date and occurring
% after every delta date with a payment amount of Installment_Amount.

installments(_, 0, _, _, []).

installments(From_Date, Num, Delta_Date, Installment_Amount, Range) :-
	date_add(From_Date, Delta_Date, Next_Date),
	Next_Num is Num - 1,
	installments(Next_Date, Next_Num, Delta_Date, Installment_Amount, Range_Tl),
	absolute_day(From_Date, Installment_Day),
	Range = [hp_installment(Installment_Day, Installment_Amount) | Range_Tl], !.

% A predicate for inserting balloon payment into a list of installments

insert_balloon(Balloon_Installment, [], [Balloon_Installment]).

% Balloon payment precedes all other payments
insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day < Inst_Hd_Day,
	Result = [Balloon_Installment | [Installments_Hd | Installments_Tl]].

% Balloon payment replaces installment on same date
insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day = Inst_Hd_Day,
	Result = [Balloon_Installment | Installments_Tl].

% Balloon payment goes into the tail of the installments
insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day > Inst_Hd_Day,
	insert_balloon(Balloon_Installment, Installments_Tl, New_Installments_Tl),
	Result = [Installments_Hd | New_Installments_Tl].

% Hard-coding the derivation for a weekly interest rate
period_interest_rate(Annual_Interest_Rate, Installment_Period, Period_Interest_Rate) :-
	Installment_Period = 7,
	Period_Interest_Rate is Annual_Interest_Rate / 52, !.

% Hard-coding the derivation for a fortnightly interest rate
period_interest_rate(Annual_Interest_Rate, Installment_Period, Period_Interest_Rate) :-
	Installment_Period = 14,
	Period_Interest_Rate is Annual_Interest_Rate / 26, !.

% Hard-coding the derivation for a monthly interest rate
period_interest_rate(Annual_Interest_Rate, Installment_Period, Period_Interest_Rate) :-
	28 =< Installment_Period,
	Installment_Period =< 31,
	Period_Interest_Rate is Annual_Interest_Rate / 12, !.

% Hard-coding the derivation for a quarterly interest rate
period_interest_rate(Annual_Interest_Rate, Installment_Period, Period_Interest_Rate) :-
	120 =< Installment_Period,
	Installment_Period =< 122,
	Period_Interest_Rate is Annual_Interest_Rate / 4, !.

% Hard-coding the derivation for a yearly interest rate
period_interest_rate(Annual_Interest_Rate, Installment_Period, Period_Interest_Rate) :-
	365 =< Installment_Period,
	Installment_Period =< 366,
	Period_Interest_Rate is Annual_Interest_Rate, !.

% Interest rate for other cases
period_interest_rate(Annual_Interest_Rate, Installment_Period, Period_Interest_Rate) :-
	Period_Interest_Rate is Annual_Interest_Rate * (Installment_Period / 365.2425).

% The following logic is used instead of relating records to their predecessors because it
% allows Prolog to systematically find all the hire purchase records corresponding to a
% given arrangement.

% Asserts the necessary relations to get from one hire purchase record to the next

hp_rec_aux(Current_Record_Number, Current_Closing_Balance, Interest_Rate, Current_Inst_Day, Installments_Hd, Next_Record) :-
	Next_Record_Number is Current_Record_Number + 1,
	hp_rec_number(Next_Record, Next_Record_Number),
	Current_Closing_Balance > 0,
	hp_rec_opening_balance(Next_Record, Current_Closing_Balance),
	hp_rec_interest_rate(Next_Record, Interest_Rate),
	hp_rec_opening_day(Next_Record, Current_Inst_Day),
	hp_inst_day(Installments_Hd, Next_Inst_Day), hp_rec_closing_day(Next_Record, Next_Inst_Day),
	hp_inst_amount(Installments_Hd, Next_Inst_Amount),
	Installment_Period is Next_Inst_Day - Current_Inst_Day,
	period_interest_rate(Interest_Rate, Installment_Period, Period_Interest_Rate),
	Next_Interest_Amount is Current_Closing_Balance * Period_Interest_Rate / 100,
	hp_rec_interest_amount(Next_Record, Next_Interest_Amount),
	hp_rec_installment_amount(Next_Record, Next_Inst_Amount),
	Next_Closing_Balance is Current_Closing_Balance + Next_Interest_Amount - Next_Inst_Amount,
	hp_rec_closing_balance(Next_Record, Next_Closing_Balance).

% Relates a hire purchase arrangement to one of its records

hp_arr_record(Arrangement, Record) :-
	hp_arr_installments(Arrangement, [Installments_Hd|Installments_Tl]),
	Current_Record_Number = 0,
	hp_arr_cash_price(Arrangement, Current_Closing_Balance),
	hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_arr_begin_day(Arrangement, Current_Inst_Day),
	hp_rec_aux(Current_Record_Number, Current_Closing_Balance, Interest_Rate, Current_Inst_Day, Installments_Hd, Next_Record),
	(Record = Next_Record; hp_rec_record(Next_Record, Installments_Tl, Record)).

% Relates a hire purchase record to one that follows it

hp_rec_record(Current_Record, [Installments_Hd|Installments_Tl], Record) :-
	hp_rec_number(Current_Record, Current_Record_Number),
	hp_rec_closing_balance(Current_Record, Current_Closing_Balance),
	hp_rec_interest_rate(Current_Record, Interest_Rate),
	hp_rec_closing_day(Current_Record, Current_Inst_Day),
	hp_rec_aux(Current_Record_Number, Current_Closing_Balance, Interest_Rate, Current_Inst_Day, Installments_Hd, Next_Record),
	(Record = Next_Record; hp_rec_record(Next_Record, Installments_Tl, Record)).

% Some predicates on hire purchase arrangements and potential installments for them

hp_arr_records(Arrangement, Records) :-
	findall(Record, hp_arr_record(Arrangement, Record), Records).

hp_arr_record_count(Arrangement, Record_Count) :-
	hp_arr_records(Arrangement, Records),
	length(Records, Record_Count).


hp_arr_total_payment_from(Arrangement, From_Day, Total_Payment) :-
	findall(Installment_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_installment_amount(Record, Installment_Amount),
		hp_rec_closing_day(Record, Closing_Day), From_Day =< Closing_Day),
		Installment_Amounts),
	sum_list(Installment_Amounts, Total_Payment).

hp_arr_total_payment_between(Arrangement, From_Day, To_Day, Total_Payment) :-
	findall(Installment_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_installment_amount(Record, Installment_Amount),
		hp_rec_closing_day(Record, Closing_Day), From_Day =< Closing_Day, Closing_Day < To_Day),
		Installment_Amounts),
	sum_list(Installment_Amounts, Total_Payment).

hp_arr_total_interest_from(Arrangement, From_Day, Total_Interest) :-
	findall(Interest_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_interest_amount(Record, Interest_Amount),
		hp_rec_closing_day(Record, Closing_Day), From_Day =< Closing_Day),
		Interest_Amounts),
	sum_list(Interest_Amounts, Total_Interest).

hp_arr_total_interest_between(Arrangement, From_Day, To_Day, Total_Interest) :-
	findall(Interest_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_interest_amount(Record, Interest_Amount),
		hp_rec_closing_day(Record, Closing_Day), From_Day =< Closing_Day, Closing_Day < To_Day),
		Interest_Amounts),
	sum_list(Interest_Amounts, Total_Interest).

% Relates a hire purchase record to a transaction to the given hire purchase account
% that is of an amount equal to that of the record and that occurs within the period of
% the record.

hp_arr_record_transaction(Arrangement, HP_Account, Record, Transactions, Transaction) :-
	hp_arr_record(Arrangement, Record),
	hp_rec_installment_amount(Record, Installment_Amount),
	hp_rec_opening_day(Record, Opening_Day), hp_rec_closing_day(Record, Closing_Day),
	member(Transaction, Transactions),
	transaction_day(Transaction, Transaction_Day),
	Opening_Day < Transaction_Day, Transaction_Day =< Closing_Day,
	transaction_vector(Transaction, Transaction_Vector),
	debit_isomorphism(Transaction_Vector, Transaction_Amount),
	Installment_Amount =:= Transaction_Amount,
	transaction_account(Transaction, HP_Account).

% Relates a hire purchase record to a duplicate transaction to the given hire purchase
% account that is of an amount equal to that of the record and that occurs within the
% period of the record.

hp_arr_record_duplicate_transaction(Arrangement, HP_Account, Record, Transactions, Duplicate_Transaction) :-
	once(hp_arr_record_transaction(Arrangement, HP_Account, Record, Transactions, Chosen_Transaction)),
	hp_arr_record_transaction(Arrangement, HP_Account, Record, Transactions, Duplicate_Transaction),
	Chosen_Transaction \= Duplicate_Transaction.
	
% Relates a hire purchase record that does not have a transaction in the above sense to a
% transaction to an incorrect account that is of an amount equal to that of the record and
% that occurs within the period of the record.

hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, Transactions, Transaction) :-
	hp_arr_record(Arrangement, Record),
	\+ hp_arr_record_transaction(Arrangement, HP_Account, Record, Transactions, _),
	hp_rec_installment_amount(Record, Installment_Amount),
	hp_rec_opening_day(Record, Opening_Day), hp_rec_closing_day(Record, Closing_Day),
	member(Transaction, Transactions),
	transaction_day(Transaction, Transaction_Day),
	Opening_Day < Transaction_Day, Transaction_Day =< Closing_Day,
	transaction_vector(Transaction, Transaction_Vector),
	debit_isomorphism(Transaction_Vector, Transaction_Amount),
	Installment_Amount =:= Transaction_Amount,
	transaction_account(Transaction, Transaction_Account),
	Transaction_Account \= HP_Account, !.

% Relates a hire purchase record that does not have a transaction in the above sense nor
% an incorrect account transaction in the above sense to a transaction to the correct
% account that is of an amount unequal to that of the record and that occurs within the
% period of the record.

hp_arr_record_wrong_amount_transaction(Arrangement, HP_Account, Record, Transactions, Transaction) :-
	hp_arr_record(Arrangement, Record),
	\+ hp_arr_record_transaction(Arrangement, HP_Account, Record, Transactions, _),
	\+ hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, Transactions, _),
	hp_rec_installment_amount(Record, Installment_Amount),
	hp_rec_opening_day(Record, Opening_Day), hp_rec_closing_day(Record, Closing_Day),
	member(Transaction, Transactions),
	transaction_day(Transaction, Transaction_Day),
	Opening_Day < Transaction_Day, Transaction_Day =< Closing_Day,
	transaction_vector(Transaction, Transaction_Vector),
	debit_isomorphism(Transaction_Vector, Transaction_Amount),
	Installment_Amount =\= Transaction_Amount,
	transaction_account(Transaction, HP_Account), !.

% Asserts that a hire purchase record does not have a transaction in the above sense, nor
% does it have an incorrect account transaction in the above sense, nor does it have an
% incorrect amount transaction in the above sense.

hp_arr_record_non_existent_transaction(Arrangement, HP_Account, Record, Transactions) :-
	hp_arr_record(Arrangement, Record),
	\+ hp_arr_record_transaction(Arrangement, HP_Account, Record, Transactions, _),
	\+ hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, Transactions, _),
	\+ hp_arr_record_wrong_amount_transaction(Arrangement, HP_Account, Record, Transactions, _).

% Relates a hire purchase record that has a duplicate transaction in the above sense to a
% pair of correction transactions that transfer from the hire purchase account to the
% missing hire purchase account.

hp_arr_record_duplicate_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, Record, Transactions, Transaction_Correction) :-
	hp_arr_record(Arrangement, Record),
	hp_arr_record_duplicate_transaction(Arrangement, HP_Account, Record, Transactions, Duplicate_Transaction),
	transaction_vector(Duplicate_Transaction, Transaction_Vector),
	vec_inverse(Transaction_Vector, Transaction_Vector_Inverted),
	member(
		Transaction_Correction,
		[
			transaction(0, correction, HP_Account, Transaction_Vector_Inverted),
			transaction(0, correction, HP_Suspense_Account, Transaction_Vector)
		]
	).

% Relates a hire purchase record that has a transaction to the incorrect account in the
% above sense to a pair of correction transactions that transfer from the incorrect
% account to the correct account.

hp_arr_record_wrong_account_transaction_correction(Arrangement, HP_Account, Record, Transactions, Transaction_Correction) :-
	hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, Transactions, Transaction),
	hp_rec_installment_amount(Record, Installment_Amount),
	transaction_account(Transaction, Transaction_Account),
	member(
		Transaction_Correction,
		[
			transaction(0, correction, HP_Account, coord(Installment_Amount, 0)),
			transaction(0, correction, Transaction_Account, coord(0, Installment_Amount))
		]
	).

% Relates a hire purchase record that has a transaction with an incorrect amount in the
% above sense to a pair of correction transactions that transfer a corrective amount
% from the missing hire purchase payments account.

hp_arr_record_wrong_amount_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, Record, Transactions, Transaction_Correction) :-
	hp_arr_record(Arrangement, Record),
	hp_arr_record_wrong_amount_transaction(Arrangement, HP_Account, Record, Transactions, Transaction),
	transaction_vector(Transaction, Transaction_Vector),
	hp_rec_installment_amount(Record, Installment_Amount),
	vec_sub(coord(Installment_Amount, 0), Transaction_Vector, Remaining_Vector),
	vec_reduce(Remaining_Vector, Remaining_Vector_Reduced),
	vec_inverse(Remaining_Vector_Reduced, Remaining_Vector_Reduced_Inverted),
	member(
		Transaction_Correction,
		[
			transaction(0, correction, HP_Account, Remaining_Vector_Reduced),
			transaction(0, correction, HP_Suspense_Account, Remaining_Vector_Reduced_Inverted)
		]
	).

% Relates a hire purchase record that does not have a transaction in any sense to a pair
% of correction transactions that transfer from the missing hire purchase payments account
% to the hire purchase account.

hp_arr_record_nonexistent_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, Record, Transactions, Transaction_Correction) :-
	hp_arr_record_non_existent_transaction(Arrangement, HP_Account, Record, Transactions),
	hp_rec_installment_amount(Record, Installment_Amount),
	member(
		Transaction_Correction,
		[
			transaction(0, correction, HP_Account, coord(Installment_Amount, 0)),
			transaction(0, correction, HP_Suspense_Account, coord(0, Installment_Amount))
		]
	).

% Relates a hire purchase arrangement to correction transactions. The correction
% transactions correct the cases where payments are made to the wrong account or where
% payments of the wrong amount are made or where no payment has been made.

hp_arr_correction(Arrangement, HP_Account, HP_Suspense_Account, Transactions, Transaction_Correction) :-
	hp_arr_record_duplicate_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, _, Transactions, Transaction_Correction);
	hp_arr_record_wrong_account_transaction_correction(Arrangement, HP_Account, _, Transactions, Transaction_Correction);
	hp_arr_record_wrong_amount_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, _, Transactions, Transaction_Correction);
	hp_arr_record_nonexistent_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, _, Transactions, Transaction_Correction).

hp_arr_corrections(Arrangement, HP_Account, HP_Suspense_Account, Transactions, Transaction_Corrections) :-
	findall(
		Transaction_Correction,
		hp_arr_correction(Arrangement, HP_Account, HP_Suspense_Account, Transactions, Transaction_Correction),
		Transaction_Corrections
	).



% liability
% interest
% unexpired
% current
% noncurrent
% balance
% repayment
% from
% between
% until/to

% check reversibility
% <currentLiability>
hp_arr_current_liability(Arrangement, Start_Day, coord(0, Signed_Cur_Liability)) :-
	next_day(Start_Day, End_Day),
	hp_arr_total_payment_between(Arrangement, Start_Day, End_Day, Signed_Cur_Liability).

% <currentUnexpiredInterest>
hp_arr_current_unexpired_interest(Arrangement, Start_Day, coord(Signed_Current_Unexpired_Interest, 0)) :-
	next_day(Start_Day, End_Day),
	hp_arr_total_interest_between(Arrangement, Start_Day, End_Day, Signed_Current_Unexpired_Interest).

% <noncurrentLiability>	
hp_arr_noncurrent_liability(Arrangement, Start_Day, coord(0, Signed_Non_Current_Liability)) :-
	next_day(Start_Day, End_Day),
	hp_arr_total_payment_from(Arrangement, End_Day, Signed_Non_Current_Liability).

% <noncurrentUnexpiredInterest>
hp_arr_noncurrent_unexpired_interest(Arrangement, Start_Day, coord(Signed_Non_Current_Unexpired_Interest, 0)) :-
	next_day(Start_Day, End_Day),
	hp_arr_total_interest_from(Arrangement, End_Day, Signed_Non_Current_Unexpired_Interest).

% check reversibility
% <repaymentBalance>
hp_arr_repayment_balance(Arrangement, Start_Day, coord(0, Signed_Repayment_Balance)) :-
	hp_arr_total_payment_from(Arrangement, Start_Day, Signed_Repayment_Balance).

% check reversibility
% <unexpiredInterest>
hp_arr_unexpired_interest(Arrangement, Start_Day, coord(Signed_Unexpired_Interest, 0)) :-
	hp_arr_total_interest_from(Arrangement, Start_Day, Signed_Unexpired_Interest).

% check reversibility
% <liabilityBalance>
hp_arr_liability_balance(Arrangement, Start_Day, Liability_Balance) :-
	hp_arr_repayment_balance(Arrangement, Start_Day, Repayment_Balance),
	hp_arr_unexpired_interest(Arrangement, Start_Day, Unexpired_Interest),
	vec_add(Repayment_Balance, Unexpired_Interest, Liability_Balance).


% one year from Start_Day
next_day(Start_Day, End_Day) :-
	gregorian_date(Start_Day, Start_Date),
	date_add(Start_Date, date(1, 0, 0), End_Date),
	absolute_day(End_Date, End_Day).

% prev_day ?
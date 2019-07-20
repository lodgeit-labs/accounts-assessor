% ===================================================================
% Project:   LodgeiT
% Module:    transaction_types.pl
% Date:      2019-06-02
% ===================================================================

:- module(transaction_types, [transaction_type_id/2,
			      transaction_type_exchanged_account_id/2,
			      transaction_type_trading_account_id/2,
			      transaction_type_description/2]).

% transaction types aka actions aka transaction descriptions aka tags

% Predicates for asserting that the fields of given transaction types have particular values

/**
 * transaction_type_id(?Transaction_Type_Term, ?Id) is det
 *
 * accessor to the identifier of this transaction type, for example 'Borrow'
 */
transaction_type_id(transaction_type(Id, _, _, _), Id).

% The account that will receive the inverse of the transaction amount after exchanging
transaction_type_exchanged_account_id(transaction_type(_, Exchanged_Account_Id, _, _), Exchanged_Account_Id).

% The account that will record the gains and losses on the transaction amount
transaction_type_trading_account_id(transaction_type(_, _, Trading_Account_Id, _), Trading_Account_Id).

% A description of this transaction type
transaction_type_description(transaction_type(_, _, _, Description), Description).

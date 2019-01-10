% Pacioli group operations
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

pacId(tterm(0, 0)).

pacAdd(tterm(A, B), tterm(C, D), Res) :-
	E is A + C,
	F is B + D,
	Res = tterm(E, F).

pacEq(tterm(A, B), tterm(C, D)) :-
	E is A + D,
	E is C + B.

pacInv(tterm(A, B), tterm(B, A)).

pacRed(tterm(A, B), C) :-
	D is A - min(A, B),
	E is B - min(A, B),
	C = tterm(D, E).

% Isomorphisms from T-Terms to signed quantities
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

creditIsomorphism(tterm(A, B), C) :- C is B - A.

debitIsomorphism(tterm(A, B), C) :- C is A - B.

% The T-Account for some hypothetical business. The schema follows:
% transaction(Date, Description, Account, TTerm).

transactions([transaction(date(17, 7, 1), investInBusiness, bank, tterm(100, 0)),
	transaction(date(17, 7, 1), investInBusiness, shareCapital, tterm(0, 100)),
	transaction(date(17, 7, 2), buyInventory, inventory, tterm(50, 0)),
	transaction(date(17, 7, 2), buyInventory, accountsPayable, tterm(0, 50)),
	transaction(date(17, 7, 3), sellInventory, accountsReceivable, tterm(100, 0)),
	transaction(date(17, 7, 3), sellInventory, sales, tterm(0, 100)),
	transaction(date(17, 7, 3), sellInventory, costOfGoodsSold, tterm(50, 0)),
	transaction(date(17, 7, 3), sellInventory, inventory, tterm(0, 50))]).

% T-Account predicates for asserting that the fields of given records have particular values

transactionDate(Index, Date) :-
	transactions(X), nth0(Index, X, transaction(Date, _, _, _)).

transactionDescription(Index, Description) :-
	transactions(X), nth0(Index, X, transaction(_, Description, _, _)).

transactionAccount(Index, Account) :-
	transactions(X), nth0(Index, X, transaction(_, _, Account, _)).

transactionTTerm(Index, TTerm) :-
	transactions(X), nth0(Index, X, transaction(_, _, _, TTerm)).

% Account types. This information was implicit in the ledger.

accountType(bank, asset).
accountType(shareCapital, equity).
accountType(inventory, asset).
accountType(accountsPayable, liability).
accountType(accountsReceivable, asset).
accountType(sales, revenue).
accountType(costOfGoodsSold, expense).

% Account isomorphisms. They are standard conventions in accounting.

accountIsomorphism(asset, debitIsomorphism).
accountIsomorphism(equity, creditIsomorphism).
accountIsomorphism(liability, creditIsomorphism).
accountIsomorphism(revenue, creditIsomorphism).
accountIsomorphism(expense, debitIsomorphism).

% accountNetActivity(Pred, FromTransIdx, ToTransIdx, NetActivity)
% Adds all the T-Terms of the transactions with indicies between FromTransIdx and ToTransIdx
% (inclusive) and that satisfy the predicate Pred.

accountNetActivity(_, FromTransIdx, ToTransIdx, tterm(0, 0)) :-
	ToTransIdx is FromTransIdx - 1.

accountNetActivity(Pred, FromTransIdx, ToTransIdx, NetActivity) :-
	ToTransIdx >= FromTransIdx,
	call(Pred, ToTransIdx),
	transactionTTerm(ToTransIdx, Curr),
	PrevTransIdx is ToTransIdx - 1,
	accountNetActivity(Pred, FromTransIdx, PrevTransIdx, Acc),
	pacAdd(Curr, Acc, NetActivity).

accountNetActivity(Pred, FromTransIdx, ToTransIdx, NetActivity) :-
	ToTransIdx >= FromTransIdx,
	PrevTransIdx is ToTransIdx - 1,
	accountNetActivity(Pred, FromTransIdx, PrevTransIdx, NetActivity).

% accountBalance(Pred, FromTransIdx, ToTransIdx, Bal)
% Adds all the T-Terms of the transactions with indicies between 0 and ToTransIdx
% (inclusive) and that satisfy the predicate Pred.

accountBalance(Pred, TransIdx, Bal) :- accountNetActivity(Pred, 0, TransIdx, Bal).

% The following predicates assert relationships between transaction dates and transaction
% indicies. They are useful because transactions are identified by their indicies (and not
% their dates) in other predicates.

% Predicate for asserting what the last index corresponding to a given date is.

lastIndex(Date, LastIndex) :-
	transactionDate(LastIndex, A),
	A @=< Date,
	AfterLastIndex is LastIndex + 1,
	transactions(Transactions),
	(length(Transactions, AfterLastIndex); (transactionDate(AfterLastIndex, B), B @> Date)).

% Predicate for asserting what the first index corresponding to a given date is.

firstIndex(Date, FirstIndex) :-
	transactionDate(FirstIndex, A),
	A @>= Date,
	BeforeFirstIndex is FirstIndex - 1,
	(BeforeFirstIndex is -1; (transactionDate(BeforeFirstIndex, B), B @< Date)).

% Now for some examples of how to use the above predicates.

% The following predicates, for example, are useful as values to be supplied to higher
% order predicates that assert things about subsets of the set of transactions.

% A predicate to indicate a transaction on an asset-typed account
assetTypedAccount(TransIdx) :-
	transactionAccount(TransIdx, TransactionAccount), accountType(TransactionAccount, asset).

% A predicate to indicate a transaction on an inventory account
inventoryAccount(TransIdx) :- transactionAccount(TransIdx, inventory).

% Let's get the balance of the inventory account after 7th transaction:
% accountBalance(inventoryAccount, 7, Bal).
% Result should be Bal = tterm(50, 50)

% What if we want the balance as a signed quantity?
% accountBalance(inventoryAccount, 7, Bal), debitIsomorphism(Bal, SignedBal).
% Result should be Bal = tterm(50, 50), SignedBal = 0.

% What is the isomorphism of the inventory account?
% accountType(inventory, AccountType), accountIsomorphism(AccountType, Isomorphism).
% Result should be AccountType = asset, Isomorphism = debitIsomorphism.

% Let's get the net activity of the asset-typed account between the 2nd and 5th transactions.
% accountNetActivity(assetTypedAccount, 2, 5, NetActivity).
% Result should be NetActivity = tterm(150, 0)

% Was the fifth transaction done on the CostOfGoodsSold account?
% transactionAccount(5, costOfGoodsSold).
% Answer is no.

% So was it done on the Sales account?
% transactionAccount(5, sales).
% Answer is yes.

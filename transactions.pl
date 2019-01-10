% The T Account for some hypothetical business.

transactionDate(0, date(17, 7, 1)).
transactionDate(1, date(17, 7, 1)).
transactionDate(2, date(17, 7, 2)).
transactionDate(3, date(17, 7, 2)).
transactionDate(4, date(17, 7, 3)).
transactionDate(5, date(17, 7, 3)).
transactionDate(6, date(17, 7, 3)).
transactionDate(7, date(17, 7, 3)).

transactionDescription(0, investInBusiness).
transactionDescription(1, investInBusiness).
transactionDescription(2, buyInventory).
transactionDescription(3, buyInventory).
transactionDescription(4, sellInventory).
transactionDescription(5, sellInventory).
transactionDescription(6, sellInventory).
transactionDescription(7, sellInventory).

transactionAccount(0, bank).
transactionAccount(1, shareCapital).
transactionAccount(2, inventory).
transactionAccount(3, accountsPayable).
transactionAccount(4, accountsReceivable).
transactionAccount(5, sales).
transactionAccount(6, costOfGoodsSold).
transactionAccount(7, inventory).

transactionTTerm(0, tterm(100, 0)).
transactionTTerm(1, tterm(0, 100)).
transactionTTerm(2, tterm(50, 0)).
transactionTTerm(3, tterm(0, 50)).
transactionTTerm(4, tterm(100, 0)).
transactionTTerm(5, tterm(0, 100)).
transactionTTerm(6, tterm(50, 0)).
transactionTTerm(7, tterm(0, 50)).

% Account types

accountType(bank, asset).
accountType(shareCapital, equity).
accountType(inventory, asset).
accountType(accountsPayable, liability).
accountType(accountsReceivable, asset).
accountType(sales, revenue).
accountType(costOfGoodsSold, expense).

% Account isomorphisms

accountIsomorphism(asset, debitIsomorphism).
accountIsomorphism(equity, creditIsomorphism).
accountIsomorphism(liability, creditIsomorphism).
accountIsomorphism(revenue, creditIsomorphism).
accountIsomorphism(expense, debitIsomorphism).

% Pacioli group operations

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

creditIsomorphism(tterm(A, B), C) :- C is B - A.

debitIsomorphism(tterm(A, B), C) :- C is A - B.

% accountNetActivity(Pred, FromTransIdx, ToTransIdx, NetActivity)

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

accountBalance(Pred, TransIdx, Bal) :- accountNetActivity(Pred, 0, TransIdx, Bal).

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

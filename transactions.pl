% The T Account for some hypothetical business.

transactionDate(transaction0, date(17, 7, 1)).
transactionDate(transaction1, date(17, 7, 1)).
transactionDate(transaction2, date(17, 7, 2)).
transactionDate(transaction3, date(17, 7, 2)).
transactionDate(transaction4, date(17, 7, 3)).
transactionDate(transaction5, date(17, 7, 3)).
transactionDate(transaction6, date(17, 7, 3)).
transactionDate(transaction7, date(17, 7, 3)).

transactionDescription(transaction0, investInBusiness).
transactionDescription(transaction1, investInBusiness).
transactionDescription(transaction2, buyInventory).
transactionDescription(transaction3, buyInventory).
transactionDescription(transaction4, sellInventory).
transactionDescription(transaction5, sellInventory).
transactionDescription(transaction6, sellInventory).
transactionDescription(transaction7, sellInventory).

transactionAccount(transaction0, bank).
transactionAccount(transaction1, shareCapital).
transactionAccount(transaction2, inventory).
transactionAccount(transaction3, accountsPayable).
transactionAccount(transaction4, accountsReceivable).
transactionAccount(transaction5, sales).
transactionAccount(transaction6, costOfGoodsSold).
transactionAccount(transaction7, inventory).

transactionType(transaction0, asset).
transactionType(transaction1, equity).
transactionType(transaction2, asset).
transactionType(transaction3, liability).
transactionType(transaction4, asset).
transactionType(transaction5, revenue).
transactionType(transaction6, expense).
transactionType(transaction7, asset).

transactionDr(transaction0, 100).
transactionDr(transaction1, 0).
transactionDr(transaction2, 50).
transactionDr(transaction3, 0).
transactionDr(transaction4, 100).
transactionDr(transaction5, 0).
transactionDr(transaction6, 50).
transactionDr(transaction7, 0).

transactionCr(transaction0, 0).
transactionCr(transaction1, 100).
transactionCr(transaction2, 0).
transactionCr(transaction3, 50).
transactionCr(transaction4, 0).
transactionCr(transaction5, 100).
transactionCr(transaction6, 0).
transactionCr(transaction7, 50).

% Was the fifth transaction done on the CostOfGoodsSold account?
% transactionAccount(transaction5, costOfGoodsSold).
% Answer is no.

% So was it done on the Sales account?
% transactionAccount(transaction5, sales).
% Answer is yes.

% Okay, so how much was credited?
% transactionCr(transaction5, X).
% Oh, so it was 100!

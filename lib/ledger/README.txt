# ledger
## introduction
This endpoint deals with the general ledger. 

```A general ledger (GL) is a set of numbered accounts a business uses to keep track of its financial transactions and to prepare financial reports. Each account is a unique record summarizing each type of asset, liability, equity, revenue and expense.```
Undertanding the basics of bookkeeping is necessary. Look in the docs/ folder, on the videos on dropbox, or for example
https://betterexplained.com/articles/understand-accounting-basics-aloe-and-balance-sheets/
https://www.khanacademy.org/economics-finance-domain/core-finance/accounting-and-financial-stateme/financial-statements-tutorial/v/balance-sheet-and-income-statement-relationship

## the frontend
Currently the only way to feed data into it is through a ledger request xml. We generate the request xml's from an excel spreadsheet file, using some templates and a .NET plugin.
The excel plugin should be available here: http://www.accrip.com.au/ftp/LodgeiTSmartExcelUtility/setup.exe
An example excel file should be in doc/ledger (Bank Demo) (todo).

## the request xml
The main sources it contains are bank statements, and also livestockData, (containing number of births, deaths, etc). Work is in progeress to also process invoices for AR/AP logic, depreciation info, and HP info.

## bank statements
A bank statement is a series of records of what amounts went into or from your bank account. Each bank account has a single currency. 

### action verbs
Users are able to annotate each record with an action verb. They are used for a high-level control of the operation of the processor. Action verbs are defined in one sheet of the excel file. An action verb currently has a name, description, an exchanged account, optional trading account, gst information..

### (some internals)
Bank statement entries are parsed into 's_transaction' terms and processed by preprocess_s_transactions. Optional livestock processing takes place before and after. The end result is a list of 'transaction' terms in a variable named Transactions, each containing the account id, date, and a list of coords.```record coord(Unit, Debit, Credit)```

The second phase consists of walking the account hierarchy and summing up transactions, and it results in a tree of ```entry(Account_Id, Balance, Child_Sheet_Entries, Transactions_Count)```. A conversion of units/currencies into a single report currency takes place here. 
A unit or currency can be for example 'GOOG' (for a share of google), or 'AUD'.
Conversion is done using a list of exchange rates supplied by the user, by lookup into a web api, or by chaining multiple exchange rates if necessary, and we also process two special unit types: 
'with_cost_per_unit' (used for at-cost reporting) and 'without_currency_movement_against_since' (used for reporting what a value of a share would be if the currency it is priced in didn't move against the report currency..)

After the entries tree is built up, we output everything as xbrl facts or dimension points.

## Bank statement processing in detail
Each s_transaction can generate multiple GL transactions. 

### bank account
First, we record the change on the bank account. This transaction is always in the currency of the bank account.

### counteraccont
An "exchange account, or "counteraccount", must be specified in the action verb. This is the basis of making the GL balance. If the bank statement record is not annotated with an exchanged unit type, then this amounts to recording a change in liabilities, revenue, expenses, or equity. The inverse of the change on the bank account is recorded on the counteraccount, but converted to report currency as of the day.

### currency_movement
If the bank account is in a different currency than the report currency, we add a "difference transaction" to the bank account's 'Currency_Movement' account, which is an earnings account. Earnings and equity accounts track, or counterbalance, the NetAssets accounts, and the total always has to be 0. see https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html .
The currency movement account is counterbalancing the change in value of the bank account. If, for example, we record 100USD credit on the bank account and 120AUD debit on the expenses account, the currency movement transaction will literally record the inverse of (100USD - 120AUD), so as USD moves against AUD, it will always equal the difference between the bank account's value and the expense account's value. 

### assets counteraccount
If the bank statement entry is annotated with an exchanged unit and units count, then these units are recorded on the counteraccount as is. For example, the s_transaction might specify that 100AUD went from the bank account, and was exchanged for 1 GOOG share. The share is recorded in the assets account specified by the transaction type. Earnings accounts are not affected. 

We also record the posession of the shares using the 'outstanding' term, ```outstanding(ST_Currency, Goods_Unit_Name, Goods_Count, Cost, Purchase_Date)```, 
ST_Currency is the s_transaction currency, which is the bank account's currency, which is the currency that we bought the shares with. Cost is recorded in report currency. When selling, items in the outstanding list are taken from the beginning or from the end, according to pricing method. The recorded original unit cost is used to record gains transactions.

### trading account
If the transaction type has a trading account specified, this is an earnings account with 2 sub-accounts: realized and unrealized gains, each containing 2 accounts: without_currency_movement and only_currency_movement. This is handled in trading.pl. The transactions on these accounts add up to a zero as long as the shares value does not change. The special without_currency_movement_against_since is used here.

You can make any pair of accounts (foo, bar) behave like Financial_Investments and Investment_Income (wrt the investments logic) by using "<exchangeAccount>foo</exchangeAccount><tradingAccount>bar</tradingAccount>" and in the actual transactions including <unit> and <unitType>.

### inventory counteraccount

This is used for livestock accounting. A method of "adjustment transactions" is used, where individual changes in livestock population do not affect the gl directly, but are instead recorded in a subsidiary ledger - livestock inventory. Cumulative changes in the inventory are used once at the report period end to adjust COGS and other accounts.

# documentation TODO
would be nice to have clickable links to predicate definitions / documentation. In theory this should be possible with pldoc, but i have not had much luck with it yet. 

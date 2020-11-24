## glossary
```
COA -
    chart of accounts

CMA -
    cash management account, a type of bank account

Non-concessional contributions:
    "Non-concessional contributions are made into your super fund from after-tax income. These contributions are not taxed in your super fund."
    - https://www.ato.gov.au/Individuals/Super/In-detail/Growing-your-super/Super-contributions---too-much-can-mean-extra-tax/?page=3
	There are caps on the non-concessional contributions you can make each financial year.

sundry:
    /ˈsʌndri/
    1. various items not important enough to be mentioned individually.
    - google
```

## COA:
```

What i suppose the program should do, in phases:

1) post all of NetAssets. Post Opening Balances for each member.
2) process bank transactions and investment statements, affecting Assets and P&L. Some of the P&L accounts are subdivided by members, so that we don't have to hunt this information down later.
3) end of year: 
	1) generate the fund's P&L report
	2) post allocation transactions, clearing out P&L into members equity accounts (excluding Opening Balance accounts)
	3) generate member reports, etc.


Some musing: notice how the program would not be able to generate the fund's P&L report from the state of the ledger after allocation transactions are posted. In what we've been doing so far (risera etc), this is sidestepped by projecting (like with an unbalanced journal entry) the total ComprehensiveIncome into Equity-CurrentEarnings after all transactions are processed. 
What if a clean-slate computerized accounting would, instead of using dr-cr pairs, use triplets:
	1) Asset changes as usual
	2) Equity tracking ownership
	3) P&L tracking reasons of asset change

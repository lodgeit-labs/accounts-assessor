### info

#### loan-0:
from excel template.

#### loan-3:
there is a missing repayment, but opening balance is set. 

#### loan10a, loan10b:
these show the difference that lodgement date makes. 
It should not affect the interest rate, 
but it should affect the minimum yearly repayment.
 * in 10a, the repayment is before lodgement, and minimum yearly repayment is met. 
 * in 10b, the repayment is after lodgement, and minimum yearly repayment is not met. 





### todo
we have relatively few testcases where zero balance is reached:
```
[19:12:11] koom@jj /home/koom/repos/koo5/div7a/data (master)  
>> grep -r "Amalgamated loan fully repaid." . | wc -l
3447
```
and we have zero ato calc testcases ending in overpayment. We may have to generate some.




===
test prompts


loan start is 2015, lodgement day is 30/6/2016, principal is 100000, term is 7 years, repayments are: 30/6/2016 $20000, 30/6/2017 $20001, 30/6/2018 $20002, 30/6/2019 $20003

loan start is 1915, lodgement day is 30/6/2016, principal is 100000, term is 7 years, repayments are: 30/6/2016 $20000, 30/6/2017 $20001, 30/6/2018 $20002, 30/6/2019 $20003   

loan start is 2015, lodgement day is 12/12/2015, principal is 100000, repayments are 10/10/1015 50000, 1/1/2016 50000


====
problems

https://www.youtube.com/watch?v=Gh2EhFTnY7U

one is in your video, where it writes a completely wrong interpretation of what the lodgement day is, another captured on screenshot below, where it interchanges "excess" with "shortfall".

Another issue i noticed is with dates, where it chooses to quietly correct year 1020 to 2020. I came up with some instructions that i try to feed it, but for what i can tell, it's as if it ignores them.

Also, notice the date 10/10/1015 in a prompt like this:
loan start is 2015, lodgement day is 12/12/2015, principal is 100000, repayments are 10/10/1015 50000, 1/1/2016 50000
Our GPT is still gonna understand the 1015 as year 2015. Bug or feature? I lean towards "bug", a "feature" would be if it at least issued a warning.


====




====
notes for users (maybe for ai too?)


Some things to notice about Division 7A calculation:
In first year after loan creation, repayments before lodgement day influence the MYR calculation, AND contribute to the total amount repaid that year.






====
ai instructions: (that ai ignores anyway)


Careful with historical dates, accurate in data handling, conservative in reinterpreting results.
Finance Wizard, adept in accounting, now comes with a specific directive to handle historical dates with utmost care. When encountering dates that seem historic, it won't automatically interpret them as typos. Instead, it will ask the user for confirmation before making any corrections. This approach ensures accuracy in dealing with historical financial data. The GPT continues to process uploaded files through its accounting calculator action. All results are relayed to user without interpreting or rewording the results, maintaining the original structure and terminology. It also continues to seek clarification on ambiguous requests while avoiding assumptions, focusing on delivering data outputs as accurately as possible.



"shortfall" and "excess" are opposite terms, you must never interchange them.

When user enters a date that is historical or otherwise seems not right, do not quietly correct it, but ask for confirmation first. 

When user uploads a file, always process it through the accounting calculator action.



===
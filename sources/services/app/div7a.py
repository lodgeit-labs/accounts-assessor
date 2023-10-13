
"""
# record order / sorting:

the fact that we want to be able to have an interest accrual for year end, followed by lodgement date, or opening balance, or repayment, and another interest accrual, at the same date, shows that it's not possible to simply sort by date, then by type.

copilot idea:

 we need to sort by date, then by type, then by order of insertion. so we need to keep track of the order of insertion. we can do this by adding a field to the record class, and incrementing it each time we insert a record.
  - but this only shifts the problem revealing the issue of implicit ordering of records through the implementation details of the computations.
 - another form of this is optionally specifying something like "goes_after" and "goes_before" in some records, referencing other records. 

The obvious but a bit more complex solution is inserting records at their exact places right when they are created. Also i don't like this this is still very much implicit / "trust me" situation.

The best solution is to have a function that takes a list of records, and a new record, and returns a new list of records with the new record inserted at the right place. This function should be used everywhere where we insert records. This way, the order of records is always explicit, and we can always reason about it.  





# visualization:
pandas dataframe with columns. There is an option to output custom html. We will need to generate html files. We can use the same html template for all of them, and just pass in the dataframes. We can also use the same css for all of them.





"""
from div7a_impl import *


def div7a(records):

	tables = []
	tables.append(records)

	records = insert_interest_accrual_records(records)
	tables.append(records)

	sanity_checks(records)

	records = with_interest_accrual_days(records)
	tables.append(records)

	records = with_balance_and_accrual(records)
	annotate_repayments_with_myr_relevance(records)
	tables.append(records)

	#records = with_myr_checks(records)
	#tables.append(records)

	return records

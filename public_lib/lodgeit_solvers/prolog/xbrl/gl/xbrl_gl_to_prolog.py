from xml.dom.minidom import parse, parseString, Node
import datetime, re

def change_case(name):
	s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
	return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

dom = parse("JournalEntries-Instance.xml")
entryHeaders = dom.getElementsByTagName("gl-cor:entryHeader")
for entryHeader in entryHeaders:
	for entryDetail in entryHeader.getElementsByTagName("gl-cor:entryDetail"):
		debit = credit = 0
		amount = int(entryDetail.getElementsByTagName("gl-cor:amount")[0].firstChild.nodeValue)
		if(entryDetail.getElementsByTagName("gl-cor:debitCreditCode")[0].firstChild.nodeValue == "C"):
			credit = amount
		else:
			debit = amount
		account_namespaced = entryDetail.getElementsByTagName("gl-cor:accountMainDescription")[0].firstChild.nodeValue
		account = change_case(account_namespaced.split(":")[-1])
		date_string = entryDetail.getElementsByTagName("gl-cor:postingDate")[0].firstChild.nodeValue
		date_object = datetime.datetime.strptime(date_string, "%Y-%m-%d")
		print("transactions(transaction(date(" + str(date_object.year) + ", " + str(date_object.month) +
			", " + str(date_object.day) + "), no_description, " + account + ", t_term(" +
			str(debit), ", " + str(credit) + "))).")
			

from arelle import (Cntlr, FileSource, ModelManager, ModelXbrl, ModelDocument, XmlUtil, Version, ViewFileFactTable, ViewFileRelationshipSet, XbrlConst)
import xml.etree.ElementTree as ET
from xml.dom import minidom
import sys

def remove_prefix(text, prefix):
    if text.startswith(prefix):
        return text[len(prefix):]
    return text

class ArelleController(Cntlr.Cntlr):
	def run(self, filepath):
		modelManager = ModelManager.initialize(self)
		modelXbrl = ModelXbrl.load(modelManager,filepath)
		output = self.getAccountHierarchyXML(modelXbrl)
		#outfile = open("account_hierarchy.xml","w")
		#outfile.write(output)
		print(output)

	def getArcRoleLinks(self,modelXbrl,arcrole):
		links = {}
		rel_set = modelXbrl.relationshipSet(arcrole)
		
		for linkFrom, value in rel_set.fromModelObjects().items():
			key = remove_prefix(str(linkFrom.qname),"basic:")
			links[key] = []
			for item in value:
				links[key].append(remove_prefix(str(item.toModelObject.qname),"basic:"))
		return links

	def printArcRoleLinks(self,modelXbrl,arcrole):
		links = self.getArcRoleLinks(modelXbrl,arcrole)
		print(arcrole)
		for linkFrom, linkToList in links.items():
			for linkTo in linkToList:
				print("{0} -> {1}".format(linkFrom,linkTo))
			print()
		print()

	def getAccountHierarchyXML(self,modelXbrl):
		summationItems = self.getArcRoleLinks(modelXbrl, XbrlConst.summationItem)

		from_elements = set()
		to_elements = set()
		for linkFrom, linkToList in summationItems.items():
			from_elements.add(linkFrom)
			for linkTo in linkToList:
				to_elements.add(linkTo)

		accountHierarchy = ET.Element("accountHierarchy")
		accountsElement = ET.Element("Accounts")
		accountHierarchy.append(accountsElement)

		root_elements = from_elements - to_elements
		for root in root_elements:
			accountsElement.append(self.XMLMakeElementAccount(root,summationItems))

		ETstring = ET.tostring(accountHierarchy).decode("utf-8")
		prettyString = minidom.parseString(ETstring).toprettyxml(indent="\t")

		return prettyString

	def XMLMakeElementAccount(self,account,links):
		accountElement = ET.Element(account)

		if account in links:
			for link in links[account]:
				subaccountElement = self.XMLMakeElementAccount(link,links)
				accountElement.append(subaccountElement)

		return accountElement


	def addToLog(self,message):
		if self.messages is not None:
			self.messages.append(message)
		else:
			print(message)
def main():
	if len(sys.argv) < 2:
		assert False, "No filepath given."
	elif len(sys.argv) > 2:
		assert False, "Too many arguments given."
	else:
		ArelleController().run(sys.argv[1])

if __name__ == "__main__":
	main()

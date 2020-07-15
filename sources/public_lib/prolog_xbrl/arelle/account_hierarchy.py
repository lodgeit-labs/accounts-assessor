#!/usr/bin/env python3

"""Extract account hierarchy from XBRL taxonomy"""

from arelle import (Cntlr, FileSource, ModelManager, ModelXbrl, ModelDocument, XmlUtil, Version, ViewFileFactTable,
					ViewFileRelationshipSet, XbrlConst)
import xml.etree.ElementTree as ET
from xml.dom import minidom
import sys
import argparse, logging


def remove_prefix_from_string(text, prefix):
	if text.startswith(prefix):
		return text[len(prefix):]
	return text


class ArelleController(Cntlr.Cntlr):
	def __init__(self, *args, **kwargs):
		self.status_logger = logging.getLogger('arelle status')
		self.status_logger.addHandler(logging.StreamHandler())
		self.status_logger.setLevel(logging.DEBUG)
		super().__init__(logFileName="logToStdErr", *args, **kwargs)

	def showStatus(self, message, clearAfter=None):
		self.status_logger.info(message)

	def run(self, filepath):
		modelManager = ModelManager.initialize(self)
		modelXbrl = ModelXbrl.load(modelManager, filepath)
		output = self.getAccountHierarchyXML(modelXbrl)
		# outfile = open("account_hierarchy.xml","w")
		# outfile.write(output)
		return output

	def getArcRoleLinks(self, modelXbrl, arcrole):
		links = {}
		rel_set = modelXbrl.relationshipSet(arcrole)

		for linkFrom, value in rel_set.fromModelObjects().items():
			key = remove_prefix_from_string(str(linkFrom.qname), "basic:")
			links[key] = []
			for item in value:
				links[key].append(remove_prefix_from_string(str(item.toModelObject.qname), "basic:"))
		return links

	def printArcRoleLinks(self, modelXbrl, arcrole):
		links = self.getArcRoleLinks(modelXbrl, arcrole)
		print(str(arcrole) + " :")
		for linkFrom, linkToList in links.items():
			for linkTo in linkToList:
				print("{0} -> {1}".format(linkFrom, linkTo))
			print()
		print()

	def test(self, model):
		arcroles = [
			XbrlConst.summationItem,
			XbrlConst.hypercubeDimension,
			XbrlConst.dimensionDomain,
			XbrlConst.domainMember,
			XbrlConst.dimensionDefault,
			XbrlConst.all,
			XbrlConst.notAll
		]
		for arcrole in arcroles:
			self.printArcRoleLinks(model, arcrole)

		print('arcroleTypes:')
		print()
		for i, j in model.arcroleTypes.items():
			print(i)
			for k in j:
				print(k)
			print()

		#for c in model.nameConcepts.items():
		import IPython; IPython.embed()

	def test_domains(self, model):
		#BankAccount_Duration
		#xbrldt:dimensionItem
		import IPython; IPython.embed()

	def printArcRoleLinks2(self, modelXbrl, arcrole):
		rel_set = modelXbrl.relationshipSet(arcrole)
		xx = rel_set.fromModelObjects().items()
		for f,t in xx:
			print()
			print(f)
			print('-->')
			for i in t:
				print(t)
			print()
		import IPython; IPython.embed()
		#

	def getAccountHierarchyXML(self, modelXbrl):

		self.test(modelXbrl)

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
			accountsElement.append(self.XMLMakeElementAccount(root, summationItems))

		ETstring = ET.tostring(accountHierarchy).decode("utf-8")
		prettyString = minidom.parseString(ETstring).toprettyxml(indent="\t")

		return prettyString

	def XMLMakeElementAccount(self, account, links):
		accountElement = ET.Element(account)

		if account in links:
			for link in links[account]:
				subaccountElement = self.XMLMakeElementAccount(link, links)
				accountElement.append(subaccountElement)

		return accountElement

	#def addToLog(self, message):
	#	if self.messages is not None:
	#		self.messages.append(message)
	#	else:
	#		print(message)


def main():
	ap = argparse.ArgumentParser(description="Extract account hierarchy from XBRL taxonomy")
	ap.add_argument("taxonomy", help="XBRL Taxonomy file-path/URL")
	args = ap.parse_args()
	print(ArelleController().run(args.taxonomy))


if __name__ == "__main__":
	main()

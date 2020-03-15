#!/usr/bin/env python3

"""

	https://allegrograph.com/using-json-ld-in-allegrograph-python-example/


"""


import os
import json, requests, copy

from franz.openrdf.sail.allegrographserver import AllegroGraphServer
from franz.openrdf.connect import ag_connect
from franz.openrdf.vocabulary.xmlschema import XMLSchema
from franz.openrdf.rio.rdfformat import RDFFormat



# Functions to create/open a repo and return a RepositoryConnection
# Modify the values of HOST, PORT, USER, and PASSWORD if necessary

user = os.environ['AGRAPH_USER']
passw = os.environ['AGRAPH_PASS']

def createdb(name):
	return ag_connect(name,host="localhost",port=10036,user=user,password=passw,create=True,clear=True)

def opendb(name):
	return ag_connect(name,host="localhost",port=10036,user=user,password=passw,create=False)

def showtriples(limit=100):
	statements = conn.getStatements(limit=limit)
	with statements:
		for statement in statements:
			print(statement)

print('conn..')
conn=createdb('jsonplay')
print('ok..')

def test(object,json_ld_context=None,rdf_context=None,maxPrint=100,conn=conn):
	conn.clear()
	conn.addData(object, allow_external_references=True)
	showtriples(limit=maxPrint)
	
person = {
"@context": "http://schema.org/",
"@type": "Person",
"@id": "foaf:person-1",
"name": "Jane Doe",
"jobTitle": "Professor",
"telephone": "(425) 123-4567",
"url": "http://www.janedoe.com"
}

#test(person)

context = {
        "name": "http://schema.org/name",
        "description": "http://schema.org/description",
        "image": {
            "@id": "http://schema.org/image", "@type": "@id" },
        "geo": "http://schema.org/geo",
        "latitude": {
            "@id": "http://schema.org/latitude", "@type": "xsd:float" },
        "longitude": {
            "@id": "http://schema.org/longitude",  "@type": "xsd:float" },
        "xsd": "http://www.w3.org/2001/XMLSchema#"
    }

place = {
    "@context": context,
    "@id": "http://franz.com/place1",
    "@graph": {
        "@id": "http://franz.com/place1",
        "@type": "http://franz.com/Place",
        "name": "The Empire State Building",
        "description": "The Empire State Building is a 102-story landmark in New York City.",
        "image": "http://www.civil.usherbrooke.ca/cours/gci215a/empire-state-building.jpg",
        "geo": {
               "latitude": "40.75",
               "longitude": "73.98" }
        }}

#test(place)


library = {
  "@context": {
    "dc": "http://purl.org/dc/elements/1.1/",
    "ex": "http://example.org/vocab#",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    "ex:contains": {
      "@type": "@id"
    }
  },
  "@id": "http://franz.com/mygraph1",
  "@graph": [
    {
      "@id": "http://example.org/library",
      "@type": "ex:Library",
      "ex:contains": "http://example.org/library/the-republic"
    }]}

#test(library)




conn=createdb("docugraph")
from jsonld_tutorial_helper import *
addNamespace(conn,"jsonldmeta","http://franz.com/ns/allegrograph/6.4/load-meta#")
addNamespace(conn,"ical","http://www.w3.org/2002/12/cal/ical#")





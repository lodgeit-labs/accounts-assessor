import rdflib
from pyld import jsonld
import json


frame = {
	"@context": {
		"@base": "https://rdf.lodgeit.net.au/v1/",
		"xsd": "http://www.w3.org/2001/XMLSchema#",
		"rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
		"rdfs": "http://www.w3.org/2000/01/rdf-schema#",
		"l": "https://rdf.lodgeit.net.au/v1/request#",
		"av": "https://rdf.lodgeit.net.au/v1/action_verbs#",
		"excel": "https://rdf.lodgeit.net.au/v1/excel#",
		"kb": "https://rdf.lodgeit.net.au/v1/kb#",
		"account_taxonomies": "https://rdf.lodgeit.net.au/v1/account_taxonomies#",
		"depr": "https://rdf.lodgeit.net.au/v1/calcs/depr#",
		"ic": "https://rdf.lodgeit.net.au/v1/calcs/ic#",
		"hp": "https://rdf.lodgeit.net.au/v1/calcs/hp#",
		"depr_ui": "https://rdf.lodgeit.net.au/v1/calcs/depr/ui#",
		"ic_ui": "https://rdf.lodgeit.net.au/v1/calcs/ic/ui#",
		"hp_ui": "https://rdf.lodgeit.net.au/v1/calcs/hp/ui#",
		"smsf": "https://rdf.lodgeit.net.au/v1/calcs/smsf#",
		"smsf_ui": "https://rdf.lodgeit.net.au/v1/calcs/smsf/ui#",
		"smsf_distribution": "https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution#",
		"smsf_distribution_ui": "https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution_ui#",
		"reallocation": "https://rdf.lodgeit.net.au/v1/calcs/ic/reallocation#"
	},
	"@type":"excel:xx"
}


g = rdflib.ConjunctiveGraph()
g.parse("RdfTemplates.n3", format="n3")
nq = g.serialize(format='nquads').decode("utf-8")
doc = jsonld.JsonLdProcessor.parse_nquads(nq)
#doc = jsonld.from_rdf(nq)
framed = jsonld.frame(doc, frame, {'omitGraph':False})
print(json.dumps(framed, indent=True))


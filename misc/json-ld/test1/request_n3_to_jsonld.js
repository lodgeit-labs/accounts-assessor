#!/usr/bin/env node
'use strict';


const processor = require('./processor.js')
var jl = require('jsonld');



const ctx = {
//	"@base": "https://rdf.lodgeit.net.au/v1/",

	"xsd": "http://www.w3.org/2001/XMLSchema#",
	"rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	"rdfs": "http://www.w3.org/2000/01/rdf-schema#",
	"excel": "https://rdf.lodgeit.net.au/v1/excel#",

/*	"depr": "https://rdf.lodgeit.net.au/v1/calcs/depr#",
	"depr_ui": "https://rdf.lodgeit.net.au/v1/calcs/depr/ui#",
	"smsf": "https://rdf.lodgeit.net.au/v1/calcs/smsf#",
	"smsf_ui": "https://rdf.lodgeit.net.au/v1/calcs/smsf/ui#",
	"smsf_distribution": "https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution#",
	"smsf_distribution_ui": "https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution_ui#",
*/
	"excel:optional":{"@type":"xsd:boolean"},
	"excel:cardinality":{"@type":"@id"},
	"excel:type":{"@type":"@id"},
	"excel:sheets":{"@type":"@id"},
	"excel:has_sheet":{"@type":"@id"},
	"excel:multiple_sheets_allowed":{"@type":"xsd:boolean"},
	"excel:is_horizontal":{"@type":"xsd:boolean"},

	"is_type_of": {"@reverse": "rdf:type2", "@container": "@set"},
	"is_range_of": {"@reverse": "rdfs:range"},

};



const frame = {
  "@context": ctx,

  //"@type":"excel:example_sheet_set",
  //"@type":"excel:sheet_set",
  //"@type":"excel:Request",
	"@id":"https://rdf.lodgeit.net.au/v1/excel_request#request"

};


(async () => {

	var doc = await processor.load_n3('../../../../lodgeitrequest.n3');
	const r = await processor.frame(doc, frame);
	console.log(JSON.stringify(r, null, 2))

})();

#!/usr/bin/env node

/*

produce RdfTemplates.json, by projecting through json-ld frames.

*/


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
	"excel:multiple_sheets_allowed":{"@type":"xsd:boolean"},

	/*"excel:class":{"@type":"@id"},
	"excel:property":{"@type":"@id"}
	^it's tempting to add these two declarations, so that the json keys don't hold objects, just the shortened strings. But if the URIs, which these objects represent, have any properties, (such as rdfs:label), then the json-ld processor produces a whole object anyway.
	I suppose it would be avoided by specifying `"@explicit": true`, but that can only be done in a frame, and, in case of our fairly complex data, i guess we'd have to specify all the intermediate objects, and what happens in case of recursion?
	it could also be specified as a global option, but then we'd have to provide the whole structure, plus, the same issue could apply..*/

};


(async () => {
	var doc = await processor.load_n3('RdfTemplates.n3');
	doc = await jl.compact(doc,ctx);
	doc['@context'] = ctx
	//console.log(doc);



	const idd = async (frame) =>
	{
		frame["@context"] = ctx;
		const fr = await processor.frame(doc, frame);
		//console.log(fr)
		return ids_to_keys(fr);
	}

	const result = {
		"help": `
The top-level keys are "sheet_sets", "example_sheet_sets" and "sheet_type". Each contains an object, whose keys are the "@id" of the nested objects.
a json-ld context was chosen such that the @id string is always the full iri of the resource.
small issue: objects have an "@id" even if it's not useful.
in excel, sheet type is in cell A2. The string is the full iri, as used to identify the sheet type in RDF.
"sheet_sets" is what the plugin should look for and send, for a given request type.
"sheet_sets" and "example_sheet_sets" reference sheet types by @id, which must be looked up in "sheet_types".
`,
		//"@context":ctx,
		sheet_sets: await idd(
			{
				"@type": "excel:sheet_set",
				"excel:sheets":
					{
						"@list": [
							{
								"@embed": "@never"
							}
						]
					}
			}
			),
		example_sheet_sets: await idd(
			{
				"@type": "excel:example_sheet_set",
				"excel:example_has_sheets":
					{
						"@list": [
							{
								"excel:has_sheet":{"@embed": "@never"}
							}
						]
					}
			}
			),
		sheet_types: await idd(
			{
				"@type": "excel:sheet_type"
			}
			),
		};
	console.log(JSON.stringify(result, null, 2))
})();

function ids_to_keys(doc)
{
	result = {};
	doc['@graph'].forEach((x) =>
		{
			result[x['@id']] = x;
		}
	);
	//result['@context'] = doc['@context'];
	return result;
}

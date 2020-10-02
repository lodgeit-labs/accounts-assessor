#!/usr/bin/env node

const processor = require('./processor.js')
var jl = require('jsonld');

const ctx = {
		"@base": "https://rdf.lodgeit.net.au/v1/",
		"xsd": "http://www.w3.org/2001/XMLSchema#",
		"rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
		"rdfs": "http://www.w3.org/2000/01/rdf-schema#",
		"excel": "https://rdf.lodgeit.net.au/v1/excel#",
		"depr": "https://rdf.lodgeit.net.au/v1/calcs/depr#",
		"depr_ui": "https://rdf.lodgeit.net.au/v1/calcs/depr/ui#",
		"smsf": "https://rdf.lodgeit.net.au/v1/calcs/smsf#",
		"smsf_ui": "https://rdf.lodgeit.net.au/v1/calcs/smsf/ui#",
		"smsf_distribution": "https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution#",
		"smsf_distribution_ui": "https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution_ui#",
		//"excel:multiple_sheets_allowed":{"@id"}
};


(async () => {
	var doc = await processor.load_n3('RdfTemplates2.n3');
	//doc = await jl.compact(doc,{});
	//console.log(doc);


	const idd = async (frame) =>
	{
		frame["@context"] = ctx;
		const fr = await processor.frame(doc, frame);
		//console.log(fr)
		return ids_to_keys(fr);
	}

	const result = {
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
	return result;
}

/*
goals:

{
	sheet_sets:
	{
		set_name1:[sheet_id1,..]
		set_name2:...
	}
	sheets:
	{
		sheet_name1:...
	}

 */

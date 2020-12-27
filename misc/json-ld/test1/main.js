#!/usr/bin/env node
'use strict';


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
	"excel:sheets":{"@type":"@id"},
	"excel:has_sheet":{"@type":"@id"},
	"excel:multiple_sheets_allowed":{"@type":"xsd:boolean"},
	"excel:is_horizontal":{"@type":"xsd:boolean"},



	/*example_doc:"excel:example_doc",
	has_sheet:"excel:has_sheet",*/



	/*"excel:class":{"@type":"@id"},
	"excel:property":{"@type":"@id"}
	^it's tempting to add these two declarations, so that the json keys don't hold objects, just the shortened strings. But if the URIs, which these objects represent, have any properties, (such as rdfs:label), then the json-ld processor produces a whole object anyway.
	I suppose it would be avoided by specifying `"@explicit": true`, but that can only be done in a frame, and, in case of our fairly complex data, i guess we'd have to specify all the intermediate objects, and what happens in case of recursion?
	it could also be specified as a global option, but then we'd have to provide the whole structure, plus, the same issue could apply..*/

	//"is_type_of": {"@reverse": "rdf:type"}
	// "a @context @reverse value must be an absolute IRI or a blank node identifier." <- nah, it works with a shortened iri too.
	// but it turns out that @reverse'ing rdf:type doesn't work .. apparently rdf:type is too special.

	"is_type_of": {"@reverse": "rdf:type2", "@container": "@set"},
	"is_range_of": {"@reverse": "rdfs:range"},
	//"is_range_of": {"@reverse": "excel:property"},


	//"rdfs:range":{"@type":"@id"},
	//"rdf:type2":{"@type":"@id"},
	/*causes:
	(node:23515) UnhandledPromiseRejectionWarning: TypeError: Cannot read property 'push' of undefined
		at Object._createInverseContext [as getInverse] (/home/koom/lodgeit2/master2/misc/json-ld/test1/node_modules/jsonld/lib/context.js:1158:28)
		at Object.api.compactIri (/home/koom/lodgeit2/master2/misc/json-ld/test1/node_modules/jsonld/lib/compact.js:707:32)
		at Object.api.compact (/home/koom/lodgeit2/master2/misc/json-ld/test1/node_modules/jsonld/lib/compact.js:204:33)
		at api.compact (/home/koom/lodgeit2/master2/misc/json-ld/test1/node_modules/jsonld/lib/compact.js:70:33)
		at Function.jsonld.compact (/home/koom/lodgeit2/master2/misc/json-ld/test1/node_modules/jsonld/lib/jsonld.js:182:25)
		at async /home/koom/lodgeit2/master2/misc/json-ld/test1/main.js:56:8
	(node:23515) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 2)
	(node:23515) [DEP0018] DeprecationWarning: Unhandled promise rejections are deprecated. In the future, promise rejections that are not handled will terminate the Node.js process with a non-zero exit code.

	//"excel:has_sheet"



*/

};


function simplify_array(x)
{
	const r = []
	x.forEach((y) =>
		r.push(simplify(y)))
	return r;
}

function simplify(x)
{
	if ((x instanceof Object) && ('@list' in x))
		return simplify_array(x['@list'])
	else if (Array.isArray(x))
		return {'@set':simplify_array(x)}
	else if (x instanceof Object)
	{
		const r = {}
		for (var [k, v] of Object.entries(x)) {
			if (k.startsWith("excel:"))
				k = k.substring("excel:".length)
			r[k] = simplify(v)
		}
		return r
	}
	else
		return x;
}

function ids_to_keys(doc)
{
	const result = {};
	doc['@graph'].forEach((x) =>
		{
			result[x['@id']] = x;
		}
	);
	//result['@context'] = doc['@context'];
	return result;
}

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
		return simplify(ids_to_keys(fr));
	}

	const result = {
		"help": `note: you may want to console.log this text for comfortable reading.
This is an anonymous object generated programmatically by https://github.com/LodgeiT/labs-accounts-assessor/blob/jld/misc/json-ld/test1/main.js. Therefore, it does not have an @id.
The top-level keys are "sheet_sets", "example_sheet_sets" and "sheet_type". Each contains an object, whose keys are the "@id" of the nested objects.
a json-ld context was chosen such that the @id string is always the full iri of the resource.
In excel, sheet type is in cell A2. The string is the full iri, as used to identify the sheet type in RDF.

"sheet_sets" is what the plugin should look for and send, for a given request type.
"sheet_sets" and "example_sheet_sets" reference sheet types by @id, which must be looked up in "sheet_types".

The format of this file is slightly overcomplicated:
Objects have an "@id" even if it's not useful.
Arrays that come from rdf lists are always wrapped in an object, whose only key is "@list". This is can be thought of either as a shortcoming of current json-ld standard, or as intentional, to allow round-tripping.

note that "is_type_of" does not exhibit this "@list" wrapping. This is because "is_type_of" value is gnerated by enumerating all iris in a certain relation to something (rdf:type relation to the parent object). These iris are not, in rdf, stored in a list.

notes on semantics of the template descriptions in general:
where "excel:type" is an "excel:uri", such as here:

                    {
                      "excel:property": {
                        "@id": "https://rdf.lodgeit.net.au/v1/calcs/hp#hp_contract_has_payment_type",
                        "rdfs:range": {
                          "@id": "https://rdf.lodgeit.net.au/v1/calcs/hp#hp_contract_payment_type"
                        }
                      },
                      "excel:type": "excel:uri"
                    },

you have to look "https://rdf.lodgeit.net.au/v1/calcs/hp#hp_contract_payment_type" up in "ranges". You will see it "is_type_of" a list of items. These are the items that show up in a dropdown.  Each item can either have "rdfs:label", in which case this is what you display to user, or you generate a label by taking the last part of the uri.


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
		ranges: await idd(
					{
						"@requireAll": true,
						"@explicit": true,
						/* the requireAll somehow doesn't require that the reverse properties are present,
						and this frame actually matches all the objects in input.
						 */
						"is_range_of":{/*"@requireAll": true, is_property_of:{}*/},
						"is_type_of":{},
						//"@type":{}
					}
			),



		};
	console.log(JSON.stringify(result, null, 2))
})();

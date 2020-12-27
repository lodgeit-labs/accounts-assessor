'use strict';

var fs = require('fs');
var path = require('path');
var n3 = require('n3');
var jl = require('jsonld');

/*import * as interop from 'ld-lib-interop';!*/
function n3lib_quad_to_jld(x)
{
	return {
		subject: n3lib_term_to_jld(x.subject),
		predicate: n3lib_term_to_jld(x.predicate),
		object: n3lib_term_to_jld(x.object),
		graph: n3lib_term_to_jld(x.graph)
	}
}

function n3lib_term_to_jld(x)
{
	const termType = x.termType;
	const value = x.value;
	switch (termType)
	{
		case 'NamedNode':
			return {termType, value}
		case 'BlankNode':
			return {termType, value: '_:' + value}
		case 'Literal':
			const r = {termType, value}
			if (x.language)
				r.language = x.language
			if (x.datatype)
				r.datatype = x.datatype
			return r
		case 'DefaultGraph':
			return {termType, value}
		default:
			throw Error('unknown termType: ' + termType)
	}
}

async function n3_file_jld_quads(fn)
{
	const store = new n3.Store();
	const parser = new n3.Parser({format: 'N3'});
	var n3_text = fs.readFileSync(fn, {encoding: 'utf-8'});
	const quads = await parser.parse(n3_text)
	const quads2 = quads.map(n3lib_quad_to_jld);
	return quads2;
}

async function add_type2_quads(quads)
{
	//hack around json-ld @reverse rdf:type problem by adding "rdf:type2" for each "rdf:type" quad.
	const to_be_added = [];
	quads.forEach((q) =>
	{
		const p = q.predicate;
		if (p.termType == "NamedNode" && p.value == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
		{
			to_be_added.push({
				subject: q.subject,
				predicate: {termType: "NamedNode", value: "http://www.w3.org/1999/02/22-rdf-syntax-ns#type2"},
				object: q.object,
				graph: q.graph
			})
		}
	})

	to_be_added.forEach((q) =>
		quads.push(q));
}

async function load_n3(fn)
{
	const quads = await n3_file_jld_quads(fn);
	add_type2_quads(quads);
	const data = await jl.fromRDF(quads);
	return data;
}

async function frame(data, frame)
{
//	const data2 = await jl.expand(data)
	const framed = await jl.frame(data, frame, {
		base: "http://ex.com/",
		processingMode: "json-ld-1.1",
		omitGraph: false,
		embed: '@always',
		ordered: true
	})
	return framed
}

exports.frame = frame;
exports.load_n3 = load_n3;

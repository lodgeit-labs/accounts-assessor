var fs = require('fs');
var path = require('path');

var n3 = require('n3');
var jl = require('jsonld');

/*import * as interop from 'ld-lib-interop';!*/
function n3lib_quad_to_jld(x)
{
	return {subject:n3lib_term_to_jld(x.subject), predicate:n3lib_term_to_jld(x.predicate), object:n3lib_term_to_jld(x.object), graph:n3lib_term_to_jld(x.graph)}
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
			return {termType, value:'_:' + value}
		case 'Literal':
			r = {termType, value}
			if(x.language)
				r.language = x.language
			if(x.datatype)
				r.datatype = x.datatype
			return r
		case 'DefaultGraph':
			return {termType, value}
		default:
			throw Error('unknown termType: ' + termType)
	}
}





async function load_n3(fn)
{
	const store = new n3.Store();
	const parser = new n3.Parser({format: 'N3'});
	var n3_text = fs.readFileSync(fn, {encoding: 'utf-8'});
	const quads = await parser.parse(n3_text)
	const quads2 = quads.map(n3lib_quad_to_jld);
	const data = await jl.fromRDF(quads2);
	return data;
}

async function frame(data, frame)
{
//	const data2 = await jl.expand(data)
	const framed = await jl.frame(data, frame, {"base":"http://ex.com/","processingMode":"json-ld-1.1","omitGraph":false})
	return framed
}

exports.frame = frame;
exports.load_n3 = load_n3;

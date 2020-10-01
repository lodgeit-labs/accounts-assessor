var fs = require('fs');
var path = require('path');

var n3 = require('n3');
var jl = require('jsonld');

async function frame(fn, frame)
{
	const store = new n3.Store();
	const parser = new n3.Parser({format: 'N3'});

	var n3_text = fs.readFileSync(fn, {encoding: 'utf-8'});

	const quads = await parser.parse(n3_text)
	const data = await jl.fromRDF(quads);

	const data2 = await jl.expand(data)

	const framed = await jl.frame(data2, frame)
	return framed
}

exports.frame = frame;

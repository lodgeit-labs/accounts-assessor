var fs = require('fs');
var path = require('path');

var n3 = require('n3');
var jl = require('jsonld');

async function expand(what)
{
	const data2 = await jl.expand(what)
	return data2
}

exports.expand = expand;

#!/usr/bin/env node

const processor = require('./processor.js');

(async () => {
	var r = await processor.expand("http://localhost:8000/remote-0008-in.jsonld");
	console.log(r)
})();

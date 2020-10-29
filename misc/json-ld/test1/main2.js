#!/usr/bin/env node

const processor = require('./processor.js')

const frame = {
  "@context": {
    "dc11": "http://purl.org/dc/elements/1.1/",
    "ex": "http://example.org/vocab#"
  },
  "@type": "ex:Library",
  "ex:contains": {
    "@type": "ex:Book"/*,
    "ex:contains": {
      "@type": "ex:Chapter"
    }*/
  }
};

const doc = {
  "@context": {
    "dc11": "http://purl.org/dc/elements/1.1/",
    "ex": "http://example.org/vocab#",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    "ex:contains": {
      "@type": "@id"
    }
  },
  "@graph": [
    {
      "@id": "http://example.org/library",
      "@type": "ex:Library",
      "ex:contains": {"@list":["http://example.org/library/the-republic","http://example.org/library/the-123"]}
    },
    /*{
      "@id": "http://example.org/brblary",
      "@type": "ex:Library",
      "ex:contains": "http://example.org/library/the-republic"
    },*/
    {
      "@id": "http://example.org/library/the-republic",
      "@type": "ex:Book",
      "dc11:creator": "Plato",
      "dc11:title": "The Republic",
      "ex:contains": "http://example.org/library/the-republic#introduction"
    },
    {
      "@id": "http://example.org/library/the-123",
      "@type": "ex:Book",
      "dc11:creator": "to",
      "dc11:title": "Thpublic",
      "ex:contains": "http://example.org/library/the-republic#introduction"
    },
    {
      "@id": "http://example.org/library/the-republic#introduction",
      "@type": "ex:Chapter",
      "dc11:description": "An introductory chapter on The Republic.",
      "dc11:title": "The Introduction"
    }
  ]
};

(async () => {
	var r = await processor.frame(doc, frame);
	console.log(JSON.stringify(r, null, 2))
})();

/*
Like `xml_flatten/2` from library(xsd/flatten) but works on already loaded XML objects instead of filepaths.
*/
flatten_xml(XML, ID) :-
	flatten:root_id(Root_ID),
	flatten:register_file_id(ID),
	flatten:xml_flatten_nodes(ID,Root_ID,0,XML),
	!.

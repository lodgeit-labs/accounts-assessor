:- debug.

:- use_module(library(http/http_path)).
http:location(pldoc, root('help/source'), [priority(10)]).

:- doc_server(4040).
:- portray_text(true).

:- [load2].

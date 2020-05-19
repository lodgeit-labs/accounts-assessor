# security issues:
# internal_services is a HTTP django RPC server that handles some OS interaction and other tasks like XML validation for prolog. This includes executing arbitrary shell commands.  If an attacker can make our code invoke http requests to arbitrary URLs, they get shell access. There is no authentication. And against standards, it invokes actions on GET requests, but that is just a convenience and can be disabled for production, and disabling that is probably all we need to do.
# invoking http GET requests to arbitrary URLs is possible through:
#  arelle, by referencing them in xbrl files referenced by users
#  fetch_file_from_url, used for fetching additional input files specified by user


# calls to load_xml from prolog: opening arbitrary files

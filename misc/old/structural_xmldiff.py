import os, sys

exit(os.system('../python/venv/bin/xmldiff ' + sys.argv[1] + ' ' + sys.argv[2] + """  | grep -v -F '[update-text-after, /' | grep -v -F '[insert-comment, /' | grep -v -F '/comment()['  """))

import json
from json import JSONEncoder, JSONDecoder
import pathlib


class MyJSONEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, pathlib.Path):
            return str(obj)
#        elif isinstance(obj, datetime):
 #           return obj.strftime('%Y-%m-%dT%H:%M:%SZ')
        else:
            return super().default(obj)
#
# class MyJSONDecoder(JSONDecoder):
#     def default(self, obj):
#         if isinstance(obj, pathlib.Path):
#             return str(obj)
# #        elif isinstance(obj, datetime):
#  #           return obj.strftime('%Y-%m-%dT%H:%M:%SZ')
#         else:
#             return super().default(obj)

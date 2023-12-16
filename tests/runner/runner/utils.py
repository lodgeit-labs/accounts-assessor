import json
from json import JSONEncoder, JSONDecoder
import pathlib
import os,subprocess,time,shlex,logging,sys,threading,tempfile


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




ss = shlex.split


def cc(cmd, **kwargs):
    logging.getLogger('robust').debug(cmd)
    return subprocess.check_call(cmd, text=True, universal_newlines=True, bufsize=1, **kwargs)

def ccss(cmd, **kwargs):
    return cc(ss(cmd), **kwargs)

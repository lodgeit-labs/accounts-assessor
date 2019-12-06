from django.http import JsonResponse
import deepdiff,json

def index(request):
	""" fixme: limit these to some directories / hosts """
	
	params = request.GET
	
	d = deepdiff.DeepDiff(
		json.load(open(params['a'],'r')),
		json.load(open(params['b'],'r')),
		**json.loads(params['options']),
		ignore_numeric_type_changes=True
	)
	
	for k,v in d.items():
		if isinstance(v, dict):
			for k2,v2 in v.items():
				if "old_value" in v2:
					if "old_type" in v2:
						del v2["old_type"]
					if "new_type" in v2:
						del v2["new_type"]
					v2["<"] = v2["old_value"]
					del v2["old_value"]
					v2[">"] = v2["new_value"]
					del v2["new_value"]
	
	return JsonResponse({'diff':d}, json_dumps_params={'default':str,'indent':4})











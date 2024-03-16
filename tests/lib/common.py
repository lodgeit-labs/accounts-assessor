import logging
import os
import subprocess
import sys
import json




logger = logging.getLogger('robust')
logging.basicConfig(level=logging.DEBUG)



def robust_tests_folder():
	return os.path.expanduser('~/robust_tests/')



internal_services_url = 'http://127.0.0.1:17787'


def print_summary_summary(summary):
	logger.info('')
	for i in summary['bad']:
		logger.info(json.dumps(i, indent=4))
		seen = []
		for delta in i['delta']:
			fix = delta.get('fix')
			if fix and (fix not in seen):
				seen.append(fix)
				if fix['op'] == 'cp':
					# quiet_success=1&
					url=internal_services_url + '/shell?cmd=cp%%20' + fix['src'] + '%%20' + fix['dst']
					title=f"cp {fix['src']} {fix['dst']}"
					os.write(sys.stderr.fileno(), subprocess.check_output(["printf", '\e]8;;'+url+'\e\\ '+title+' \e]8;;\e\\\n'], stderr=subprocess.PIPE))	
					url=internal_services_url + '/shell?cmd=kdiff3%%20' + fix['src'] + '%%20' + fix['dst']
					title=f"kdiff3 {fix['src']} {fix['dst']}"
					os.write(sys.stderr.fileno(), subprocess.check_output(["printf", '\e]8;;'+url+'\e\\ '+title+' \e]8;;\e\\\n'], stderr=subprocess.PIPE))	
	logger.info(summary['stats'])
	logger.info('')

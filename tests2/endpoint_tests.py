#!/usr/bin/env python3




import glob
import requests




def enumerate_testcases():
        dirs = glob.glob('endpoint_tests/*/*/')
        dirs.sort()
        for dir in dirs:
            print(dir)
        return dirs
    
        
run_request(robust_server_url, tmp_dir):
	requests.post(
		robust_server_url	+ '/upload', 
		file1=
		file2=
		
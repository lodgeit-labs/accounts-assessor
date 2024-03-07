#!/usr/bin/env python3
from pathlib import PosixPath

import fire, os

class Tools:
	def ensure_every_testcase_dir_has_results_folder_not_responses_folder(self, directory: PosixPath):
		print(directory)
		for root, dirs, files in os.walk(directory):
			#print(root, dirs, files)
			for dir in dirs:
				if dir == 'responses':
					d = os.path.join(root, dir)
					print(root, dir)
					os.rename(d, os.path.join(root, 'results'))

fire.Fire(Tools)

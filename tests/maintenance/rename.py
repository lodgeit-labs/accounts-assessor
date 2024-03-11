#!/usr/bin/env python3
import subprocess
from pathlib import PosixPath

import fire, os

class Tools:
	def migrate(self, directory: PosixPath):
		print('migrate root', directory)
		for root, dirs, files in os.walk(directory):
			#print(root, dirs, files)
			for dir in dirs:
				# if dir == 'responses':
				# 	d = os.path.join(root, dir)
				# 	print(root, dir)
				# 	#os.rename(d, os.path.join(root, 'results'))
				# if dir == 'request':
				# 	d = os.path.join(root, dir)
				# 	print(root, dir)
				# 	os.rename(d, os.path.join(root, 'inputs'))
				if dir == 'results':
					d = os.path.join(root, dir)
					print('found testcase results dir:')
					for root, dirs, files in os.walk(d):
						print(root, dirs, files)
						for file in files:
								
							rename(d,'balance_sheet.html', '000000_final_balance_sheet.html')
							rename(d,'profit_and_loss.html', '000000_profit_and_loss.html')
							rename(d,'investment_report.html', '000000_investment_report.html')
							rename(d,'investment_report.json', '000000_investment_report.json')
							rename(d,'investment_report_since_beginning.html', '000000_investment_report_since_beginning.html')
							rename(d,'investment_report_since_beginning.json', '000000_investment_report_since_beginning.json')
							rename(d,'investment_report_since_beginning.json', '000000_investment_report_since_beginning.json')
							rename(d,'reports_json.json', '000000_reports_json.json')
							
							# if file in ['xbrl_instance.xml', 'cashflow.html', 'crosschecks.html', 'general_ledger_json.json', , 'investment_report.html', 'investment_report.json', 'investment_report_since_beginning.html', 'investment_report_since_beginning.json', 'link.html', 'profit_and_loss.html', 'profit_and_loss_historical.html', 'reports_json.json', 'request.xml']:
							# 	subprocess.check_call(['git', 'mv', os.path.join(d, file), os.path.join(d, '000000_' + file)])
							# 
							

def rename(d, a,b):
	a = os.path.join(d, a)
	b = os.path.join(d, b)
	if os.path.exists(a):
		if not os.path.exists(b):
			subprocess.check_call(['git', 'mv', a, b])
					

fire.Fire(Tools)

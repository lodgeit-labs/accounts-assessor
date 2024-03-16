import datetime
import time
import luigi


class AbortableTask(luigi.Task):
	accepts_messages = True
	should_die = False

	ts = luigi.Parameter('_')

	def proces_msgs(self):
		if not self.scheduler_messages.empty():
			self.process_msg(self.scheduler_messages.get())

	def process_msg(self, msg):
		print(msg)
		if msg.content == "die":
			self.should_die = True
			msg.respond("okay")
		else:
			msg.respond("unknown message")

	def check_die(self):
		self.proces_msgs()
		return self.should_die

	def run(self):
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		self.output().open('w').close()

	def output(self):
		return luigi.LocalTarget('/tmp/bar/%s' % (self.ts))



class ImmediateComputation(luigi.Task):
	test = luigi.parameter.DictParameter()


	def run(self):
		inputs = self.copy_inputs()
		self.run_request(inputs)


	def copy_inputs(self):
		request_files_dir: pathlib.Path = P(self.test['path']) / 'inputs'
		request_files_dir.mkdir(parents=True)
		files = []
		input_file: pathlib.Path
		for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('*'))):
			shutil.copyfile(input_file, request_files_dir / input_file.name)
			files.append(request_files_dir / input_file.name)
		return files


	def run_request(self, inputs):
		url = self.test['robust_server_url']
		logging.getLogger('robust').debug('')
		logging.getLogger('robust').debug('querying ' + url)


		requests.post(
				url + '/upload',
				files={'file1':open(inputs[0])}
		)

		# time.sleep(10)
		# logging.getLogger('robust').debug('...')
		# time.sleep(10)
		# logging.getLogger('robust').debug('...')


		o = self.output()
		P(o.path).mkdir(parents=True)
		with open(P(o.path) / 'result.xml', 'w') as r:
			r.write('rrrr')


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'outputs')








--


#reports = self.reportlist_from_saved_responses_directory(results.path)
def reportlist_from_saved_responses_directory(self, path):
	return [{'fn' : f} for f in P(path).glob('*')]


# result = xmlparse(result_fn).getroot()
# expected = xmlparse(expected_fn).getroot()


# just nope, xmldiff produces total trash
"""
<LoanSummary>
    <IncomeYear>2020</IncomeYear>
    <OpeningBalance>9355</OpeningBalance>
    <InterestRate>5.37</InterestRate>
    <MinYearlyRepayment>2183.00</MinYearlyRepayment>
    <TotalRepayment>5507.00</TotalRepayment>
    <RepaymentShortfall>0</RepaymentShortfall>
    <TotalInterest>482.97</TotalInterest>
    <TotalPrincipal>5024.03</TotalPrincipal>
    <ClosingBalance>4330.97</ClosingBalance>
</LoanSummary>


<LoanSummary>
    <IncomeYear>2020</IncomeYear>
    <OpeningBalance>9355.0000008</OpeningBalance>
    <InterestRate>5.3700008</InterestRate>
    <MinYearlyRepayment>2182.9166668</MinYearlyRepayment>
    <TotalRepayment>5507.0000008</TotalRepayment>
    <RepaymentShortfall>0.0000008</RepaymentShortfall>
    <TotalInterest>485.1050568</TotalInterest>
    <TotalPrincipal>0.0000008</TotalPrincipal>
    <ClosingBalance>3848.0000008</ClosingBalance>
</LoanSummary>




        [DeleteNamespace(prefix='xsi'), DeleteAttrib(node='/LoanSummary[1]', name='{http://www.w3.org/2001/XMLSchema-instance}schemaLocation'), 
        
        
        MoveNode(node='/LoanSummary/OpeningBalance[1]', target='/LoanSummary[1]', position=2), 
        
        InsertNode(target='/LoanSummary[1]', tag='OpeningBalance', position=1), UpdateTextIn(node='/LoanSummary/OpeningBalance[1]', text='9355'), InsertNode(target='/LoanSummary[1]', tag='InterestRate', position=2), UpdateTextIn(node='/LoanSummary/InterestRate[1]', text='5.37'), RenameNode(node='/LoanSummary/InterestRate[2]', tag='MinYearlyRepayment'), UpdateTextIn(node='/LoanSummary/MinYearlyRepayment[1]', text='2183.00'), RenameNode(node='/LoanSummary/OpeningBalance[2]', tag='TotalRepayment'), UpdateTextIn(node='/LoanSummary/TotalRepayment[1]', text='5507.00'), InsertNode(target='/LoanSummary[1]', tag='RepaymentShortfall', position=5), UpdateTextIn(node='/LoanSummary/RepaymentShortfall[1]', text='0'), InsertNode(target='/LoanSummary[1]', tag='TotalInterest', position=6), UpdateTextIn(node='/LoanSummary/TotalInterest[1]', text='482.97'), RenameNode(node='/LoanSummary/TotalInterest[2]', tag='TotalPrincipal'), UpdateTextIn(node='/LoanSummary/TotalPrincipal[1]', text='5024.03'), InsertNode(target='/LoanSummary[1]', tag='ClosingBalance', position=11), UpdateTextIn(node='/LoanSummary/ClosingBalance[1]', text='4330.97'), DeleteNode(node='/LoanSummary/ClosingBalance[2]'), DeleteNode(node='/LoanSummary/TotalPrincipal[2]'), DeleteNode(node='/LoanSummary/RepaymentShortfall[2]'), DeleteNode(node='/LoanSummary/TotalRepayment[2]'), DeleteNode(node='/LoanSummary/MinYearlyRepayment[2]')]






left:
<LoanSummary xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="loan_response.xsd"><IncomeYear>2020</IncomeYear><OpeningBalance>9355.0000008</OpeningBalance><InterestRate>5.3700008</InterestRate><MinYearlyRepayment>2182.9166668</MinYearlyRepayment><TotalRepayment>5507.0000008</TotalRepayment><RepaymentShortfall>0.0000008</RepaymentShortfall><TotalInterest>483.7796328</TotalInterest><TotalPrincipal>0.0000008</TotalPrincipal><ClosingBalance>3848.0000008</ClosingBalance></LoanSummary>

right:
<LoanSummary><IncomeYear>2020</IncomeYear><OpeningBalance>9355</OpeningBalance><InterestRate>5.37</InterestRate><MinYearlyRepayment>2183.00</MinYearlyRepayment><TotalRepayment>5507.00</TotalRepayment><RepaymentShortfall>0</RepaymentShortfall><TotalInterest>482.97</TotalInterest><TotalPrincipal>5024.03</TotalPrincipal><ClosingBalance>4330.97</ClosingBalance></LoanSummary>

diff:
<LoanSummary xmlns:diff="http://namespaces.shoobx.com/diff" diff:delete-attr="{http://www.w3.org/2001/XMLSchema-instance}schemaLocation">
  <IncomeYear>2020</IncomeYear>
  <OpeningBalance diff:delete="">9355.0000008</OpeningBalance>
  <OpeningBalance diff:insert="" diff:rename="ClosingBalance">9355</OpeningBalance>
  <InterestRate>5.37<diff:delete>00008</diff:delete></InterestRate>
  <MinYearlyRepayment diff:insert="" diff:rename="RepaymentShortfall">2183.00</MinYearlyRepayment>
  <TotalRepayment diff:insert="" diff:rename="OpeningBalance">5507.00</TotalRepayment>
  <RepaymentShortfall diff:insert="" diff:rename="TotalPrincipal">0</RepaymentShortfall>
  <TotalInterest diff:rename="MinYearlyRepayment"><diff:delete>21</diff:delete><diff:insert>4</diff:insert>82.9<diff:delete>166668</diff:delete><diff:insert>7</diff:insert></TotalInterest>
  <TotalPrincipal diff:rename="TotalRepayment"><diff:delete>5</diff:delete>50<diff:delete>7.0000008</diff:delete><diff:insert>24.03</diff:insert></TotalPrincipal>
  <RepaymentShortfall diff:delete="">0.0000008</RepaymentShortfall>
  <ClosingBalance diff:rename="TotalInterest">4<diff:delete>83.7796328</diff:delete><diff:insert>330.97</diff:insert></ClosingBalance>
  <TotalPrincipal diff:delete="">0.0000008</TotalPrincipal>
  <ClosingBalance diff:delete="">3848.0000008</ClosingBalance>
</LoanSummary>
"""

# diff = []
# xml_diff = xmldiff.main.diff_files(
# 	#result_fn, 
# 	#expected_fn,
# 	StringIO(canonical_result_xml_string),
# 	StringIO(canonical_expected_xml_string),
# 	formatter=xmldiff.formatting.XMLFormatter(
# 		normalize=xmldiff.formatting.WS_BOTH,
# 		pretty_print=True,
# 	),
# 	diff_options = dict(
# 		F=0,
# 		ratio_mode='accurate'
# 	)
# )
# logger.info(xml_diff)

# if xml_diff != "":

# this is useless because we'll always have float numerical differences
# 	diff.append(xml_diff)
# 	diff.append(xmldiff.main.diff_files(result_fn, expected_fn))

# 	shortfall = expected.find("./LoanSummary/RepaymentShortfall")
# 	if shortfall is not None:
# 		shortfall = shortfall.text
# 	
# 	diff.append(dict(
# 		type='div7a',
# 		failed=result.tag == 'error',
# 		expected_shortfall=shortfall
# 	))






# https://github.com/timtadh/zhang-shasha is interesting,
#also the idea of specifying our own edit distance function for numerical nodes.
# but if it doesn't produce the actual diffs, how do you then inspect the diffs?
#go back to xmldiff and get all the noise with float numerical differences again?






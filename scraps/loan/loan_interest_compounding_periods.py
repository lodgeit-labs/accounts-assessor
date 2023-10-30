#!/usr/bin/env python3

"""
this shows how interest compounds under different compounding frequencies
"""



import matplotlib.pyplot as plt
from collections import OrderedDict



yearly_interest = 0.05
monthly_interest = yearly_interest / 12
daily_interest = yearly_interest / 365 # correct approximately 3 of every 4 years



def daily():
	p = 100000
	for i in range(365*3+1):
		print(p)
		yield((i,p))
		p = p + p * daily_interest



def monthly():
	p = 100000
	for i in range(36+1):
		print(p)
		yield((i*365/12,p))
		p = p + p * monthly_interest



def yearly():
	p = 100000
	for i in range(3+1):
		print(p)
		yield((i*365,p))
		p = p + p * yearly_interest



def simple():
	p = 100000
	q = p
	for i in range(3+1):
		print(q)
		yield((i*365,q))
		q = q + p * yearly_interest






funcs = [daily, monthly, yearly, simple]

graphs = OrderedDict()

for set in funcs:
	name = set.__name__
	print(name)
	d  = list(zip(*set()))
	graphs[name] = dict(plot=plt.plot(d[0], d[1], label=name))
	print()

for l,(k,v) in zip(plt.legend().get_lines(), graphs.items()):
	l.set_picker(True)
	l.set_pickradius(10)
	v['label'] = l

def on_pick(event):
	legend = event.artist
	isVisible = legend.get_visible()
	for k,v in graphs.items():
		if v['label'] == legend:
			v['plot'][0].set_visible(not isVisible)
	legend.set_visible(not isVisible)
	plt.draw()

print(graphs)

plt.connect('pick_event', on_pick)
plt.show()
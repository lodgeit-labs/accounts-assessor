from sympy import *

assets = Symbol("assets")
equity = Symbol("equity")
liabilities = Symbol("liabilities")
vs = []
for i in range(10):
	vs.append(Symbol("x"+str(i)))
accounting_equation = Eq(vs[0] - liabilities,equity)
print(solve(accounting_equation,liabilities))

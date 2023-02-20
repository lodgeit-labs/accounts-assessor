import sys, os
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tasking import remoulade


@remoulade.actor
def ping():
	return "pong"

print(remoulade.get_broker().actors)

import logging, subprocess, datetime
from config import secret



log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.debug("debug fly_machines.py")



server_started_time = datetime.datetime.now()
fly_machines = {}



def flyctl():
	#os.system('pwd')
	#os.system('which flyctl')
	return '/home/myuser/.fly/bin/flyctl -t "'+ secret('FLYCTL_API_TOKEN') + '" '




def start_machine(machine):
	cmd = f'{flyctl()} machines start {machine["id"]}'
	log.debug(cmd)
	subprocess.run(cmd, shell=True)
	fly_machines[machine['id']] = dict(started=datetime.datetime.now(), machine=machine)



def stop_machine(machine):
	cmd = f'{flyctl()} machines stop {machine["id"]}'
	log.debug(cmd)
	subprocess.run(cmd, shell=True)


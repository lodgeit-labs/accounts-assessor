#!/usr/bin/env python3


import subprocess, fire, shlex, io, libtmux, logging
#logging.getLogger('libtmux').setLevel(logging.WARNING)


def run(compose_events_cmd, tmux_session_name: str):
	tmux_session_name = str(tmux_session_name)

	tmux_server = libtmux.Server()
	print(tmux_session_name.__repr__())
	print(tmux_server.sessions)
	tmux_session = tmux_server.sessions.get(name=tmux_session_name)

	#cmd = 'docker-compose  -f ../generated_stack_files/docker-stack__mount_host_sources_dir__debug_frontend_server__enable_public_insecure__use_host_network__compose__secrets_dir__omit_services.yml -p robust --compatibility events'

	cmd = shlex.split('stdbuf -oL -eL ' + compose_events_cmd)
	proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
	for line in io.TextIOWrapper(proc.stdout, encoding="utf-8"):
		print(line)
		if 'container start' in line:
			s = line.split()
			container_id = s[4]
			tmux_session.new_window(window_shell=f'echo {line}; docker logs -f ' + container_id)



if __name__ == '__main__':
  fire.Fire(run)

#
# on_key(k):
# 	if k == 't':
# 		mode = not mode
# 		init()
#
# def init()
# 	if mode:
#
#
#

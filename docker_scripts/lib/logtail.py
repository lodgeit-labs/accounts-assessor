#!/usr/bin/env python3


import subprocess, fire, shlex, io, libtmux, logging
#logging.getLogger('libtmux').setLevel(logging.WARNING)


def run(compose_events_cmd, tmux_session_name: str):
	tmux_session_name = str(tmux_session_name)

	tmux_server = libtmux.Server()
	print(tmux_session_name.__repr__())
	print(tmux_server.sessions)
	tmux_session = tmux_server.sessions.get(name=tmux_session_name)

	cmd = shlex.split('stdbuf -oL -eL ' + compose_events_cmd + ' events')
	proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
	for line in io.TextIOWrapper(proc.stdout, encoding="utf-8"):
		if 'container start' in line or 'container die' in line:
			print(line)
		if 'container start' in line:
			s = line.split()
			container_id = s[4]
			line_quoted = shlex.quote(line)
			tmux_session.new_window(window_name="logs", window_shell=f'echo {line_quoted}; docker logs -f ' + container_id + ' | cat; cat')



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

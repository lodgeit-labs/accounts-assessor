#!/usr/bin/env python3


import subprocess, shlex, os
	
if 'DISPLAY' in os.environ:
	if subprocess.call(shlex.split('xhost +local:docker')) != 0:
		print('maybe you need:')
		print('sudo apt install x11-xserver-utils')



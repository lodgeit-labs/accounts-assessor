#!/usr/bin/env python3



import click, shlex, subprocess




# use this to run a request in docker, possibly with guitracer. internal services and rabbitmq have to be running.
# you need this to run a request with an image built to bind sources dir




subprocess.check_call(['./xhost.py'])
subprocess.check_call(['./git_info.fish'])





#!/usr/bin/env python3


import os,subprocess,time,shlex,logging,sys,threading,tempfile


flag = '../generated_stack_files/build_done'

os.unlink(flag)

ExcThread(target=health_check).start()

subprocess.check_call(shlex.split('./develop.sh --parallel_build true --public_url "http://robust10.local:8877"'))

def health_check():
    while True:
        try:
            open(flag)
            break
        except:
            pass
    time.sleep(10)
    try:
        subprocess.check_call(shlex.split("""curl -L -S --fail --max-time 320 --header 'Content-Type: application/json' --data '---' http://localhost/health_check"""))
        exit(0)
    except:
        exit(1)

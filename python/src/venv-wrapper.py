import sys
import os
import subprocess

# probably some terrible injection attack you can do here
# like:
# > python3 venv-wrapper.py "; echo \"arbitrary shell command execution\""
#
# could probably be doing all of this from prolog, but then would probably actually be more difficult to deal w/ this shell-injection issue
# * python at least might have some built-in way to call directly into python w/o going through the shell like this.
def main():
	script_root = "../xbrl/account_hierarchy"
	activate_path = script_root + "/venv/bin/activate"
	script_path = script_root + sys.argv[1]
	python_command = "python3 {0} {1}".format(script_path, " ".join(sys.argv[2:]))
	full_command = "source {0} ; {1} ; deactivate".format(activate_path, python_command)

	output = subprocess.Popen(full_command, stdout=subprocess.PIPE, shell=True, executable="/bin/bash").stdout.read().decode("utf-8")
	print(output)

if __name__ == "__main__":
	main()

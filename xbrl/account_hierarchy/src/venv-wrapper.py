import sys
import os
import subprocess

# probably some terrible injection attack you can do here
# like:
# > python3 venv-wrapper.py "; echo \"arbitrary shell command execution\""
def main():
	script_root = "../xbrl/account_hierarchy"
	activate_path = script_root + "/venv/bin/activate"
	script_path = script_root + "/src/main.py"
	python_command = "python3 {0} {1}".format(script_path, " ".join(sys.argv[1:]))
	full_command = "source {0} ; {1} ; deactivate".format(activate_path, python_command)

	output = subprocess.Popen(full_command, stdout=subprocess.PIPE, shell=True, executable="/bin/bash").stdout.read().decode("utf-8")
	print(output)

if __name__ == "__main__":
	main()

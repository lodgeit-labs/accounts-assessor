#! /bin/sh
if [ -d venv ]
then
	echo "./venv exists, exiting"
	exit 0
fi
python3.9 -m venv venv
. venv/bin/activate
python3.9 -m pip install wheel
python3.9 -m pip install -r requirements.txt 

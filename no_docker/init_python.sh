#! /bin/sh
if [ -d venv ]
then
	echo "./venv exists, exiting"
	exit 0
fi
python3.8 -m venv venv
. venv/bin/activate
python3.8 -m pip install wheel
python3.8 -m pip install -r sources/requirements.txt 

#! /bin/sh
if [ -d venv ]
then
	exit 0
fi
python3.8 -m venv venv
. venv/bin/activate
python3.8 -m pip install wheel
python3.8 -m pip install -r requirements.txt 

install:
`
python3 -m venv venv
pip3 install -r requirements.txt
`

run:
`
. venv/bin/activate
celery -A services1 worker -l info
`


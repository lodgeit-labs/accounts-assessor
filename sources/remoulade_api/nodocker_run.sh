#!/usr/bin/env fish

FLASK_APP=main \
FLASK_ENV=development \
FLASK_DEBUG=1 \
PYTHONUNBUFFERED=1 \
RABBITMQ_URL='localhost:5672' \
REDIS_HOST='redis://localhost' \
REMOULADE_PG_URI='postgresql://remoulade@localhost:5432/remoulade' \
./start.sh


#!/bin/sh
celery -c 1  -E -A c worker --loglevel=debug

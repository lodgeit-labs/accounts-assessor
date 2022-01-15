FROM koo5/ubuntu

RUN apt-get install -yqq libpq-dev
WORKDIR /app/
COPY . /app/sources/
RUN python3 -m pip install --no-cache-dir -r /app/sources/remoulade_api/requirements.txt
RUN python3 -m pip install --no-cache-dir -e /app/sources/common/libs/remoulade[rabbitmq,redis,postgres]

ENV FLASK_APP=main
ENV FLASK_ENV=development
ENV FLASK_DEBUG=1
ENV PYTHONUNBUFFERED=1

VOLUME /app/sources/

ENTRYPOINT ["/app/sources/remoulade_api/start.sh"]


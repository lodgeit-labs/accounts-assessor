FROM koo5/ubuntu

RUN apt-get install -yqq libpq-dev
WORKDIR /app/
COPY remoulade_api/requirements.txt .
RUN python3 -m pip install --no-cache-dir -r requirements.txt

COPY common/libs/remoulade /app/remoulade
COPY common/tasking.py /app/remoulade/remoulade/api/

RUN python3 -m pip install --no-cache-dir -e /app/remoulade[rabbitmq,redis,postgres]


WORKDIR /app/remoulade/remoulade/api

ENV FLASK_APP=main
ENV FLASK_ENV=development
ENV FLASK_DEBUG=1
ENV PYTHONUNBUFFERED=1

#ENTRYPOINT ["python3", "main.py"]
ENTRYPOINT ["flask", "run", "-h", "0.0.0.0", "--no-debugger", "--no-reload"]


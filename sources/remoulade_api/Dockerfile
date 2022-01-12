FROM koo5/ubuntu

RUN apt-get install -yqq libpq-dev
WORKDIR /app/
COPY common/libs/remoulade /app/remoulade
COPY remoulade_api/requirements.txt .
RUN python3 -m pip install --no-cache-dir -r requirements.txt

WORKDIR /app/

ENV FLASK_APP=main
ENV FLASK_ENV=development

ENTRYPOINT ["python3", "remoulade/remoulade/api"]
#ENTRYPOINT ["flask", "run"]


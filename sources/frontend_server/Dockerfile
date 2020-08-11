FROM ubuntu:18.04
RUN apt-get update && apt-get install -y git python3 python3-pip \
 && rm -rf /var/lib/apt/lists/*
RUN groupadd -r user && useradd -r -g user user
RUN mkdir /app
WORKDIR /app
#COPY requirements.txt .
COPY frontend_server/requirements_minimal.txt .
RUN pip3 install --no-cache-dir -r requirements_minimal.txt
EXPOSE 7788
RUN mkdir -p /app/server_root
#RUN chown -R user:user /app/server_root
#RUN chown -R user:user /app/server_root
VOLUME /app/server_root
COPY frontend_server /app/sources/frontend_server
COPY internal_workers /app/sources/internal_workers
COPY triplestore_access /app/sources/triplestore_access
COPY common /app/sources/common
COPY static /app/sources/static
COPY secrets1.json /
COPY secrets2.json /
#USER user
WORKDIR /app/frontend_server
ENV PYTHONUNBUFFERED true
ENV PYTHONDONTWRITEBYTECODE 1
ENV CELERY_QUEUE_NAME=q7788
ENTRYPOINT ["./start.sh"]
CMD ["--noreload", "0.0.0.0:7788"]

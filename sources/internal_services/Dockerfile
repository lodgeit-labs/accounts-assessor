FROM ubuntu:18.04
RUN apt-get update && apt-get install -y git python3 python3-pip \
 && rm -rf /var/lib/apt/lists/*
RUN groupadd -r user && useradd -r -g user user
RUN mkdir /app
WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
EXPOSE 17788
RUN mkdir -p /app/server_root
RUN chown user:user /app/server_root
VOLUME /app/server_root
COPY public_lib /app/sources/public_lib
COPY internal_services /app/sources/internal_services
COPY static /app/sources/static
#USER user
WORKDIR /app/sources/internal_services
ENV PYTHONUNBUFFERED true
ENTRYPOINT ["./start.sh"]
CMD ["--noreload", "0.0.0.0:17788"]

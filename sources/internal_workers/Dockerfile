FROM ubuntu:18.04

#todo: this is multi-stage build, are the base image tags guaranteed to resolve to the same images for both stages?
#FROM koo5/swipl as swipl
#^that didnt work
RUN mkdir /app
WORKDIR /app
RUN apt-get update && apt-get install -y \
        git \
        build-essential cmake ninja-build pkg-config \
        ncurses-dev libreadline-dev libedit-dev \
        libunwind-dev \
        libgmp-dev \
        libssl-dev \
        unixodbc-dev \
        zlib1g-dev libarchive-dev \
        libossp-uuid-dev \
        libxext-dev libice-dev libjpeg-dev libxinerama-dev libxft-dev \
        libxpm-dev libxt-dev \
        libdb-dev \
        libpcre3-dev \
        libyaml-dev \
        && rm -rf /var/lib/apt/lists/*
RUN git clone --branch V8.1.15 https://github.com/SWI-Prolog/swipl-devel.git
WORKDIR swipl-devel
RUN git submodule update --init
RUN mkdir build
WORKDIR build
RUN cmake -G Ninja ..
RUN ninja
RUN ctest -j 8
RUN ninja install


RUN apt-get update && apt-get install -y cmake ninja-build git python3 python3-pip \
 && rm -rf /var/lib/apt/lists/*
RUN groupadd -r user && useradd -r -g user user
#RUN mkdir /app
WORKDIR /app


#COPY --from=0 /app/swipl-devel/build /app/swipl-devel/build
#WORKDIR /app/swipl-devel/build
#RUN ninja install


WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
EXPOSE 17788
RUN mkdir -p /app/server_root
#RUN chown user:user /app/server_root
VOLUME /app/server_root
COPY internal_workers ./internal_workers
COPY git_info.txt .
COPY secrets2.json /
#USER user
WORKDIR /app/internal_workers
ENV PYTHONUNBUFFERED true
ENV CELERY_QUEUE_NAME=q7788
ENTRYPOINT ["./start.sh"]
CMD ["-n", "worker7788", "--loglevel=info"]

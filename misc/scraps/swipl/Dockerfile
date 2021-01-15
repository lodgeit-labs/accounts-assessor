# i tried to do swipl build in a standalone container and only copy the results over, but you cant `make install` (or `ninja install`) without the sources, so this is unused.

FROM ubuntu:18.04

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

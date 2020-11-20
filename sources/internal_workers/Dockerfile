FROM ubuntu:18.04


env LOC en_AU.UTF-8
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y locales language-pack-en \
    && sed -i -e 's/# $LOC UTF-8/$LOC UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=$LOC
ENV LANG $LOC
ENV LC_ALL $LOC


RUN mkdir /app
WORKDIR /app
        # apt-get update \
        # && 
RUN     apt-get install -y \
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


#RUN git clone --branch V8.3.10 https://github.com/SWI-Prolog/swipl.git swipl-devel
RUN git clone --branch V8.1.15 https://github.com/SWI-Prolog/swipl.git swipl-devel
WORKDIR swipl-devel
RUN git submodule update --init --recursive


WORKDIR packages/xpce
RUN true
RUN git remote add koo5 https://github.com/koo5/packages-xpce.git
RUN git fetch koo5
RUN git cherry-pick -n koo5/more_eye_friendly_gtrace_color_theme_squashed


WORKDIR /app/swipl-devel
RUN mkdir build
WORKDIR build
RUN cmake -G Ninja ..
RUN ninja
RUN ctest -j 8 --output-on-failure
RUN ninja install


RUN apt-get update && apt-get install -y cmake ninja-build git python3 python3-pip \
 && rm -rf /var/lib/apt/lists/*
RUN groupadd -r user && useradd -r -g user user
WORKDIR /app



COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt


COPY init_prolog.sh .
RUN ./init_prolog.sh


RUN mkdir -p /app/server_root
#RUN chown user:user /app/server_root
VOLUME /app/server_root
COPY static /app/sources/static
COPY internal_workers /app/sources/internal_workers
COPY triplestore_access /app/sources/triplestore_access
COPY common /app/sources/common
COPY public_lib /app/sources/public_lib
COPY lib /app/sources/lib
#RUN mkdir ./cache
#COPY cache ./cache
VOLUME /app/cache
COPY secrets2.json /
#USER user
WORKDIR /app/sources/internal_workers


ENV PYTHONUNBUFFERED true
ENV CELERY_QUEUE_NAME=q7788
ENV DETERMINANCY_CHECKER__USE__ENFORCER=true


#VOLUME /tmp/.X11-unix
COPY swipl/Defaults /root/.config/swi-prolog/xpce/Defaults


ENTRYPOINT ["./start.sh"]
CMD ["-n", "worker7788", "--loglevel=info"]

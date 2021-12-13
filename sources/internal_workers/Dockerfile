FROM koo5/workers-hlw${PP}:latest


COPY wait-for-it /app/sources/wait-for-it
COPY static /app/sources/static
COPY internal_workers /app/sources/internal_workers
COPY common /app/sources/common
COPY config /app/sources/config
COPY public_lib /app/sources/public_lib
COPY lib /app/sources/lib

USER myuser

COPY --chown=myuser:myuser  swipl/xpce/* /home/myuser/.config/swi-prolog/xpce/

WORKDIR /app/sources/internal_workers

LABEL mode=full


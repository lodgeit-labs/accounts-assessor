FROM koo5/workers-hlw${PP}:latest


WORKDIR /app/sources/
COPY wait-for-it .
COPY static .
COPY workers .
COPY common .
COPY config .
COPY public_lib .
COPY lib .

USER myuser

COPY --chown=myuser:myuser  swipl/xpce/* /home/myuser/.config/swi-prolog/xpce/

WORKDIR /app/sources/workers

LABEL mode=full


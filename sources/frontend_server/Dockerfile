FROM koo5/frontend-hlw${PP}:latest

USER root

COPY frontend_server /app/sources/frontend_server
COPY internal_workers /app/sources/internal_workers
COPY common /app/sources/common
COPY static /app/sources/static

USER myuser

CMD ["--noreload", "0.0.0.0:7788"]


FROM koo5/frontend_server${PP}:latest

COPY frontend_server /app/sources/frontend_server
COPY internal_workers /app/sources/internal_workers
COPY triplestore_access /app/sources/triplestore_access
COPY common /app/sources/common
COPY static /app/sources/static

CMD ["--noreload", "0.0.0.0:7788"]


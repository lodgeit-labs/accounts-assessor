FROM koo5/internal-workers${PP}:latest

COPY static /app/sources/static
COPY internal_workers /app/sources/internal_workers
COPY triplestore_access /app/sources/triplestore_access
COPY common /app/sources/common
COPY public_lib /app/sources/public_lib
COPY lib /app/sources/lib

WORKDIR /app/sources/internal_workers

LABEL mode=full


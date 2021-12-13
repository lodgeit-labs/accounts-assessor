FROM koo5/services-hlw${PP}:latest

COPY public_lib /app/sources/public_lib
COPY internal_services /app/sources/internal_services
COPY static /app/sources/static

CMD ["--noreload", "0.0.0.0:17788"]

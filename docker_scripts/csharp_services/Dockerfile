FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build-env
WORKDIR /App

COPY . ./
RUN dotnet restore

#RUN dotnet publish -c Release -o out
RUN dotnet publish -c Debug -o out



# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:7.0

RUN apt update; apt install -y curl fonts-noto-core


WORKDIR /App
COPY --from=build-env /App/out .

ARG uid=1000
ARG gid=1000
RUN groupadd -g $gid myuser && useradd -lm -u $uid -g $gid myuser

VOLUME /app/server_root/tmp
USER myuser

VOLUME /App/RdfTemplates.n3
VOLUME /home/myuser/.dotnet


ENTRYPOINT ["dotnet", "CsharpServices.dll"]
ENV HC="curl -L -S --fail http://127.0.0.1:17789/health" 









#start interval is the time between health checks during the start period. This option requires Docker Engine version 25.0 or later.
USER root
RUN mkdir /healthcheck
RUN chown myuser:myuser /healthcheck
USER myuser
HEALTHCHECK --interval=2s --timeout=60s CMD { test -f /healthcheck/ok && echo -n "sleep.." && sleep 55 && echo -n "hc..>> " && /bin/sh -c '/bin/sh -c "$HC"' && echo -n " <<..hc passed." ; } || { echo -n "hc..>> " && echo -n "$HC" && echo -n " <<... " && /bin/sh -c '/bin/sh -c "$HC"' && echo -n " << first hc passed." && touch /healthcheck/ok && echo " flag stored." ; } 



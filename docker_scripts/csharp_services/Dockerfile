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
USER myuser

VOLUME /App/RdfTemplates.n3

HEALTHCHECK --interval=5s --timeout=50s --start-period=5s --retries=3 CMD curl -L -S --fail http://127.0.0.1:17789/health

ENTRYPOINT ["dotnet", "CsharpServices.dll"]

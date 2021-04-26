FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine
ENV DOTNET_CLI_TELEMETRY_OPTOUT true
ENV DOTNET_NOLOGO true

RUN apk --update --no-cache add nodejs nodejs-npm jq curl bash git && \
    npm install -g aws-cdk

COPY entrypoint.sh /entrypoint.sh

RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]
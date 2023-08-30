FROM mcr.microsoft.com/dotnet/sdk:7.0-alpine

ENV DOTNET_CLI_TELEMETRY_OPTOUT true
ENV DOTNET_NOLOGO true

# Install .NET SDK 6.0 for compatibility
COPY --from=mcr.microsoft.com/dotnet/sdk:6.0-alpine /usr/share/dotnet/sdk /usr/share/dotnet/sdk

RUN apk --update --no-cache add nodejs npm jq curl bash git && \
    npm install -g aws-cdk

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
